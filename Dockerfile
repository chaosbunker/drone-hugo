FROM amd64/golang:1.16-alpine AS builder

WORKDIR /build

ENV HUGO_VERSION=0.83.1

ENV GOOS=linux
ENV GOARCH=amd64
ENV CGO_ENABLED=0
ENV GO111MODULE=on

RUN apk --no-cache add git

RUN go get github.com/drone-plugins/drone-hugo

COPY . .

RUN go build -v -a -tags netgo -o release/linux/amd64/drone-hugo

RUN apk add --no-cache git build-base && \
  git clone --branch v${HUGO_VERSION} https://github.com/gohugoio/hugo.git && \
  cd hugo/ && \
  CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/gohugoio/hugo/common/hugo.buildDate=$(date +%Y-%m-%dT%H:%M:%SZ) -X github.com/gohugoio/hugo/common/hugo.commitHash=$(git rev-parse --short HEAD)" -o /tmp/hugo . && \
  CGO_ENABLED=1 go build -tags extended -ldflags "-s -w -X github.com/gohugoio/hugo/common/hugo.buildDate=$(date +%Y-%m-%dT%H:%M:%SZ) -X github.com/gohugoio/hugo/common/hugo.commitHash=$(git rev-parse --short HEAD)" -o /tmp/hugo-extended

FROM plugins/base:linux-amd64

LABEL maintainer="Dennis Rodewyk <ufo@chaosbunker.com>" \
  org.label-schema.name="Drone Hugo"

COPY --from=builder /go/bin/drone-hugo /bin
COPY --from=builder /tmp/hugo /bin/hugo
COPY --from=builder /tmp/hugo-extended /bin/hugo-extended

ENTRYPOINT ["/bin/drone-hugo"]
