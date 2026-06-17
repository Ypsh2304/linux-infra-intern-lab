# syntax=docker/dockerfile:1
FROM python:3.12-alpine

ENV INFRA_DEMO_HOST=0.0.0.0 \
    INFRA_DEMO_PORT=8080 \
    INFRA_DEMO_LOG_DIR=/tmp/infra-demo \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
RUN addgroup -S infra && adduser -S -G infra infra
COPY --chown=infra:infra service/infra-demo/python_server/infra_demo.py /app/infra_demo.py

USER infra
EXPOSE 8080
CMD ["python", "/app/infra_demo.py"]
