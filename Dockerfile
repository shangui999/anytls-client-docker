FROM alpine:3.21

ARG TARGETARCH
ARG VERSION=0.0.12

# 基础环境变量
ENV PASS=your_password \
    HOST=your_host \
    PORT=8443 \
    HTTP_PORT=10809

# 暴露 HTTP 代理端口
EXPOSE ${HTTP_PORT}

# 直接从 Alpine 仓库安装 privoxy，省去下载逻辑
RUN apk add --no-cache curl unzip privoxy

# 1. 安装 anytls
RUN curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_${TARGETARCH}.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/anytls-client && \
    rm /tmp/anytls.zip && \
    apk del curl unzip

# 2. 准备启动脚本
# Privoxy 需要一个配置文件才能启动
RUN echo "listen-address  0.0.0.0:${HTTP_PORT}" > /etc/privoxy/config && \
    echo "forward-socks5t / 127.0.0.1:10808 ." >> /etc/privoxy/config && \
    echo "keep-alive-timeout 5" >> /etc/privoxy/config && \
    echo "socket-timeout 300" >> /etc/privoxy/config && \
    # 允许所有连接
    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:10809/g' /etc/privoxy/config

# 3. 运行逻辑
# Privoxy 默认会以非 root 用户运行，我们这里直接通过命令行指定配置
ENTRYPOINT anytls-client -l 127.0.0.1:10808 -s anytls://${PASS}@${HOST}:${PORT} & \
           privoxy --no-daemon /etc/privoxy/config