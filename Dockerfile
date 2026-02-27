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

# 2. 下载 gost (修复了架构转换逻辑)
RUN case "${TARGETARCH}" in \
      "amd64") GOST_ARCH="amd64" ;; \
      "arm64") GOST_ARCH="armv8" ;; \
      "arm")   GOST_ARCH="armv7" ;; \
      *)       GOST_ARCH="${TARGETARCH}" ;; \
    esac && \
    curl -L -o /tmp/gost.gz "https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.gz" && \
    gunzip /tmp/gost.gz && \
    # gunzip 会去掉 .gz 后缀，保留原始文件名，通常是 gost_2.11.5_linux_xxx
    mv /tmp/gost_* /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost

RUN rm -rf /tmp/* && apk del curl unzip

# 启动 anytls (SOCKS5) 并通过 gost 转为 HTTP 代理
# anytls 监听 127.0.0.1 保证安全，gost 监听 0.0.0.0 对外提供服务
ENTRYPOINT anytls-client -l 127.0.0.1:10808 -s anytls://${PASS}@${HOST}:${PORT} & \
           gost -L http://:10809?target=127.0.0.1:10808