FROM alpine:3.21

ARG TARGETARCH
ARG VERSION=0.0.12
ARG GOST_VERSION=2.12.0

ENV PASS=your_password \
    HOST=your_host \
    PORT=8443 \
    HTTP_PORT=10809

EXPOSE ${HTTP_PORT}

RUN apk add --no-cache curl unzip tar

# 1. 下载 anytls
RUN curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_${TARGETARCH}.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/anytls-client

# 2. 下载 gost v2.12.0 (处理 .tar.gz 格式)
RUN case "${TARGETARCH}" in \
      "amd64") GOST_ARCH="amd64" ;; \
      "arm64") GOST_ARCH="armv8" ;; \
      "arm")   GOST_ARCH="armv7" ;; \
      *)       GOST_ARCH="${TARGETARCH}" ;; \
    esac && \
    URL="https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.tar.gz" && \
    curl -L -f -o /tmp/gost.tar.gz "$URL" && \
    # 解压并只提取名为 gost 的二进制文件到 /usr/local/bin/
    tar -xzvf /tmp/gost.tar.gz -C /usr/local/bin/ gost && \
    chmod +x /usr/local/bin/gost

RUN rm -rf /tmp/* && apk del curl unzip

# 3. 启动脚本
# 使用 & 将 anytls 放入后台，gost 在前台运行
ENTRYPOINT anytls-client -l 127.0.0.1:10808 -s anytls://${PASS}@${HOST}:${PORT} & \
           gost -L http://:10809?target=127.0.0.1:10808