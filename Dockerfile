# Relay del online (tools/relay.py) — contenedor minimo, solo Python stdlib.
# Se construye y despliega con `fly deploy` (fly.toml); el mismo Dockerfile
# sirve para cualquier otro host de contenedores.
FROM python:3.12-alpine

COPY tools/relay.py /app/relay.py

ENV PYTHONUNBUFFERED=1
EXPOSE 24565/udp
USER nobody
CMD ["python", "/app/relay.py"]
