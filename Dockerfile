FROM alpine:3.21

ARG VERSION=0.0.12
# 建议通过 docker run -e 传参，不要在 Dockerfile 里写死敏感信息
ENV PASS=your_password \
    HOST=your_host \
    PORT=8443

EXPOSE 10808

# 合并 RUN 指令，减少镜像层数并真正清理缓存
RUN apk add --no-cache curl unzip && \
    curl -L -o /tmp/anytls.zip "https://github.com/anytls/anytls-go/releases/download/v${VERSION}/anytls_${VERSION}_linux_amd64.zip" && \
    unzip /tmp/anytls.zip -d /usr/local/bin/ && \
    # 确保权限，并根据 zip 内部实际结构重命名或移动二进制文件
    chmod +x /usr/local/bin/anytls-client && \
    # 清理垃圾
    rm /tmp/anytls.zip && \
    apk del curl unzip

# 使用绝对路径，并修复引号嵌套问题
# 如果需要环境变量展开，建议直接使用 shell 格式
ENTRYPOINT anytls-client -l 0.0.0.0:10808 -s anytls://${PASS}@${HOST}:${PORT}