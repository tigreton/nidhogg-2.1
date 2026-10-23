#!/usr/bin/env bash
# Orquestador del E2E online (secundarias.md: "Orquestador del E2E online").
#
# Automatiza el procedimiento manual de docs/online-netcode.md: copia el
# proyecto a dos carpetas (cada una con su caché .godot propia — dos
# instancias del MISMO directorio pisan la caché y la segunda puede no ver su
# script, "File not found"), importa los recursos en cada copia, lanza el
# host headless en segundo plano y el cliente en primer plano contra
# 127.0.0.1, y reporta los dos RESULT con un exit code agregado.
#
# Uso:
#   tools/online_e2e.sh                    # puerto 24575 (no pisar el 24565 de dev)
#   tools/online_e2e.sh --port 24600       # puerto distinto
#   tools/online_e2e.sh --latency 80       # ida y vuelta por tools/netem_proxy.py
#   tools/online_e2e.sh --keep             # conservar las copias y logs (depurar)
#   GODOT=/ruta/a/godot tools/online_e2e.sh
#
# Requisitos: bash (Git Bash en Windows / linux en CI), tar, timeout;
# con --latencia además python (3.8+, solo stdlib).
# Salida: 0 si HOST_RESULT y CLIENT_RESULT son ambos OK, 1 en cualquier fallo.

set -u

PORT=24575
IP=127.0.0.1
KEEP=0
HOST_WAIT=6
LATENCY=0

while [ $# -gt 0 ]; do
	case "$1" in
		--port) PORT="$2"; shift 2 ;;
		--port=*) PORT="${1#--port=}"; shift ;;
		--ip) IP="$2"; shift 2 ;;
		--ip=*) IP="${1#--ip=}"; shift ;;
		--latency) LATENCY="$2"; shift 2 ;;
		--latency=*) LATENCY="${1#--latency=}"; shift ;;
		--keep) KEEP=1; shift ;;
		--help|-h)
			sed -n '2,20p' "$0"; exit 0 ;;
		*) echo "argumento desconocido: $1 (ver --help)"; exit 1 ;;
	esac
done

# --- binario de Godot: GODOT explícito > binario del escritorio > PATH -----
if [ -z "${GODOT:-}" ]; then
	DESKTOP_BIN="C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe"
	if [ -x "$DESKTOP_BIN" ]; then
		GODOT="$DESKTOP_BIN"
	else
		GODOT="godot"
	fi
fi
if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
	echo "E2E FALLO: no encuentro el binario de Godot ('$GODOT') — exporta GODOT=/ruta/a/godot"
	exit 1
fi

# --- caminos nativos para el exe de Godot (MSYS convierte mal --path=/x) ---
SRC="$(cd "$(dirname "$0")/.." && pwd)"
native() {
	if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/nidhogg-e2e-XXXXXX")"
HOST_DIR="$WORK/host"
CLIENT_DIR="$WORK/client"
mkdir -p "$HOST_DIR" "$CLIENT_DIR"

HOST_PID=""
PROXY_PID=""
CLIENT_PORT="$PORT"
cleanup() {
	if [ -n "$HOST_PID" ] && kill -0 "$HOST_PID" 2>/dev/null; then
		kill "$HOST_PID" 2>/dev/null
	fi
	if [ -n "$PROXY_PID" ] && kill -0 "$PROXY_PID" 2>/dev/null; then
		kill "$PROXY_PID" 2>/dev/null
	fi
	if [ "$KEEP" = "1" ]; then
		echo "E2E: copias y logs conservados en $WORK"
	else
		rm -rf "$WORK"
	fi
}
trap cleanup EXIT

# --- 2b) red mala inyectada (opcional): proxy UDP con delay/loss ------------
if [ "$LATENCY" -gt 0 ] 2>/dev/null; then
	PYTHON="${PYTHON:-$(command -v python3 || command -v python)}"
	if [ -z "$PYTHON" ]; then
		echo "E2E FALLO: --latency necesita python (3.8+) en el PATH o en \$PYTHON"
		exit 1
	fi
	PROXY_PORT=$((PORT + 1))
	DELAY=$((LATENCY / 2))
	JITTER=$((LATENCY / 8)); [ "$JITTER" -gt 10 ] && JITTER=10
	echo "E2E: netem proxy ${IP}:${PROXY_PORT} -> ${IP}:${PORT}  (${LATENCY}ms RTT = ${DELAY}ms±${JITTER} por dirección, 0.5% de pérdida)"
	"$PYTHON" "$SRC/tools/netem_proxy.py" --listen "${IP}:${PROXY_PORT}" --target "${IP}:${PORT}" \
		--delay "$DELAY" --jitter "$JITTER" --loss 0.5 --seed 20261023 >"$WORK/netem.log" 2>&1 &
	PROXY_PID=$!
	CLIENT_PORT="$PROXY_PORT"
	sleep 1
fi

echo "E2E: godot   = $GODOT"
echo "E2E: origen  = $SRC"
echo "E2E: destino = $WORK  (puerto $PORT, ip $IP)"

# --- 1) dos copias del proyecto, sin lo pesado ni regenerable --------------
# (~15 MB por copia: project.godot + scripts + scenes + test + art + docs)
copy_tree() { # $1 = destino
	tar -C "$SRC" -cf - \
		--exclude=.git --exclude=.godot --exclude=.zcode \
		--exclude=art_raw --exclude=media --exclude=build --exclude=screens \
		--exclude=__pycache__ --exclude=trace_motion.csv \
		. | tar -C "$1" -xf -
}
echo "E2E: copiando el proyecto a las dos carpetas..."
copy_tree "$HOST_DIR"   || { echo "E2E FALLO: copia del host"; exit 1; }
copy_tree "$CLIENT_DIR" || { echo "E2E FALLO: copia del cliente"; exit 1; }

# --- 2) import de recursos en cada copia (caché .godot propia) -------------
run_import() { # $1 = carpeta, $2 = log
	"$GODOT" --headless --path "$(native "$1")" --import >"$2" 2>&1
}
echo "E2E: importando recursos (cada copia construye su caché)..."
if ! run_import "$HOST_DIR" "$WORK/host-import.log"; then
	echo "E2E FALLO: import del host — cola del log:"; tail -20 "$WORK/host-import.log"; exit 1
fi
if ! run_import "$CLIENT_DIR" "$WORK/client-import.log"; then
	echo "E2E FALLO: import del cliente — cola del log:"; tail -20 "$WORK/client-import.log"; exit 1
fi

# --- 3) host en segundo plano, espera, cliente en primer plano -------------
echo "E2E: lanzando HOST (puerto $PORT)..."
"$GODOT" --headless --path "$(native "$HOST_DIR")" --audio-driver Dummy \
	--script test/online_host.gd -- --port="$PORT" >"$WORK/host.log" 2>&1 &
HOST_PID=$!

sleep "$HOST_WAIT"

echo "E2E: lanzando CLIENTE (${IP}:${CLIENT_PORT})..."
timeout 180 "$GODOT" --headless --path "$(native "$CLIENT_DIR")" --audio-driver Dummy \
	--script test/online_client.gd -- --ip="$IP" --port="$CLIENT_PORT" >"$WORK/client.log" 2>&1
CLIENT_RC=$?

# el host se auto-cierra a los ~40 s; esperar su veredicto
wait "$HOST_PID" 2>/dev/null
HOST_RC=$?
HOST_PID=""

# --- 4) veredicto agregado --------------------------------------------------
echo
echo "================ HOST (últimas líneas) ================"
tail -6 "$WORK/host.log"
echo "================ CLIENTE (últimas líneas) ============="
tail -6 "$WORK/client.log"
echo "======================================================="

HOST_LINE="$(grep -a 'HOST_RESULT' "$WORK/host.log" | tail -1)"
CLIENT_LINE="$(grep -a 'CLIENT_RESULT' "$WORK/client.log" | tail -1)"
echo "$HOST_LINE"
echo "$CLIENT_LINE"

VERDICTO=OK
if [ "$HOST_RC" -ne 0 ] || [ -z "$HOST_LINE" ] || ! printf '%s' "$HOST_LINE" | grep -q 'HOST_RESULT: OK'; then
	VERDICTO=FALLO
fi
if [ "$CLIENT_RC" -ne 0 ] || [ -z "$CLIENT_LINE" ] || ! printf '%s' "$CLIENT_LINE" | grep -q 'CLIENT_RESULT: OK'; then
	VERDICTO=FALLO
fi
echo "E2E ONLINE: $VERDICTO (host rc=$HOST_RC, cliente rc=$CLIENT_RC)"
[ "$VERDICTO" = "OK" ]
