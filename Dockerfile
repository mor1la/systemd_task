FROM eclipse-temurin:17-jre-jammy@sha256:8a21b8680d754f9f953b8285fb140879979a3b1fe038c1491df6dc0f9a04a1d3

ARG APP_DIR
ARG APP_BIN

ENV APP_BIN=${APP_BIN}

WORKDIR /opt/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY ${APP_DIR}/ /opt/app/

RUN chmod +x "/opt/app/bin/${APP_BIN}" \
    && groupadd -r appgroup \
    && useradd -r -g appgroup appuser \
    && chown -R appuser:appgroup /opt/app

USER appuser

ENTRYPOINT ["sh", "-c", "exec ./bin/${APP_BIN} -Dconfig.file=${CONFIG_FILE_PATH} -Dhttp.port=${PORT} -Dfile.encoding=UTF8"]