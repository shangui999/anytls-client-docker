FROM alpine:3.21

ARG TARGETARCH
ARG VERSION=0.0.12
# 新增 gost 版本
ARG GOST_VERSION=2.11.5

ENV PASS=your_password \
    HOST=your_host \
    PORT=8443 \
    HTTP_PORT=10809

# 暴露新的 HTTP 端口
EXPOSE ${HTTP_PORT}

RUN apk add --no-cache curl unzip

# 下载 anytls
RUN curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_${TARGETARCH}.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/anytls-client

# 下载 gost (用于 SOCKS5 转 HTTP)
# 注意：gost 的架构命名与 TARGETARCH 略有不同（arm64 对应 armv8）
RUN if [ "${TARGETARCH}" = "arm64" ]; then GOST_ARCH="armv8"; else GOST_ARCH=${TARGETARCH}; fi && \
    curl -L -o /tmp/gost.gz "https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.gz" && \
    gunzip /tmp/gost.gz && \
    mv /tmp/gost /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost

RUN rm -rf /tmp/* && apk del curl unzip

# 启动脚本：先启 anytls (SOCKS5)，再启 gost (SOCKS5 to HTTP)
ENTRYPOINT anytls-client -l 127.0.0.1:10808 -s anytls://${PASS}@${HOST}:${PORT} & \
           gost -L http://:10809?target=127.0.0.1:10808