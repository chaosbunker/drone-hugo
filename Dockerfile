FROM golang:alpine AS builder

WORKDIR /build

ENV GOOS=linux
ENV GOARCH=amd64
ENV CGO_ENABLED=0
ENV GO111MODULE=on

RUN apk --no-cache add git

RUN go get github.com/drone-plugins/drone-hugo

COPY . .

RUN go build -v -a -tags netgo -o release/linux/amd64/drone-hugo

FROM plugins/base:linux-amd64

LABEL maintainer="Dennis Rodewyk <ufo@chaosbunker.com>" \
  org.label-schema.name="Drone Hugo"

ENV HUGO_VERSION=0.62.0
ENV HUGO_ARCH=64bit
ENV PLUGIN_HUGO_ARCH=$HUGO_ARCH
ENV PLUGIN_HUGO_SHIPPED_VERSION=$HUGO_VERSION

RUN apk --no-cache add git && \
    wget -O- https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-${HUGO_ARCH}.tar.gz | tar xz -C /bin

COPY --from=builder /go/bin/drone-hugo /bin

ENTRYPOINT ["/bin/drone-hugo"]
