FROM alpine:3.21

# Docker Buildx 自动提供的变量
ARG TARGETARCH

ARG VERSION=0.0.12
# 建议通过 docker run -e 传参
ENV PASS=your_password \
    HOST=your_host \
    PORT=8443

EXPOSE 10808

RUN apk add --no-cache curl unzip && \
    # 👉 关键修改：将 amd64 替换为 ${TARGETARCH}
    # 根据 anytls 的 GitHub Release 命名规则，TARGETARCH 正好对应得上
    curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_${TARGETARCH}.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/anytls-client && \
    rm /tmp/anytls.zip && \
    apk del curl unzip

ENTRYPOINT anytls-client -l 0.0.0.0:10808 -s anytls://${PASS}@${HOST}:${PORT}