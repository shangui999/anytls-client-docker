FROM alpine:3.21

ARG TARGETARCH
ARG VERSION=0.0.12
ARG GOST_VERSION=2.11.5

ENV PASS=your_password \
    HOST=your_host \
    PORT=8443 \
    HTTP_PORT=10809

EXPOSE ${HTTP_PORT}

RUN apk add --no-cache curl unzip

# 1. 下载 anytls
RUN curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_${TARGETARCH}.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/anytls-client

# 2. 下载 gost (修正下载逻辑)
RUN case "${TARGETARCH}" in \
      "amd64") GOST_ARCH="amd64" ;; \
      "arm64") GOST_ARCH="armv8" ;; \
      "arm")   GOST_ARCH="armv7" ;; \
      *)       GOST_ARCH="${TARGETARCH}" ;; \
    esac && \
    # 使用 -f 参数让 curl 在 404 时直接报错退出，方便排查
    curl -L -f -o /tmp/gost.gz "https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.gz" && \
    gunzip /tmp/gost.gz && \
    # 强制移动解压后的文件
    mv /tmp/gost_* /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost

RUN rm -rf /tmp/* && apk del curl unzip

# 3. 使用 shell 格式启动，确保变量生效
# anytls 监听 127.0.0.1 (内部)，gost 监听 0.0.0.0 (对外)
ENTRYPOINT anytls-client -l 127.0.0.1:10808 -s anytls://${PASS}@${HOST}:${PORT} & \
           gost -L http://:${HTTP_PORT}?target=127.0.0.1:10808