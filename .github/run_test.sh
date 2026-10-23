#!/usr/bin/env bash
# Harness de la batería para CI (y uso local): ejecuta res://test/$1.tscn
# headless, exige exit code 0 Y que la salida contenga $2 (subcadena de la
# línea de aprobación — sin acentos, para no pelearse con el locale).
#   GODOT=/ruta/a/godot bash .github/run_test.sh smoke_test "SMOKE OK"
set -o pipefail

NAME="$1"
WANT="$2"
LOG="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/${NAME}.log"

"$GODOT" --headless --path . "res://test/${NAME}.tscn" 2>&1 | tee "$LOG"
RC="${PIPESTATUS[0]}"

if [ "$RC" -ne 0 ]; then
	echo "FALLO: godot terminó con rc=${RC} en ${NAME}"
	exit "$RC"
fi
if ! grep -aqF "$WANT" "$LOG"; then
	echo "FALLO: '${WANT}' no apareció en la salida de ${NAME}; últimas líneas:"
	tail -15 "$LOG"
	exit 1
fi
echo "CI OK: ${NAME} → ${WANT}"
