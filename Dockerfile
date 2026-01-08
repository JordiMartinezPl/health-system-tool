FROM alpine:latest

RUN apk add --no-cache \
    bash \
    curl \
    procps \
    coreutils \
    iproute2 \
    util-linux \
    bc \
    grep \
    sed \
    gawk

WORKDIR /app
COPY health-check.sh .
RUN chmod +x health-check.sh

ENV POSIXLY_CORRECT=1

CMD ["./health-check.sh"]
