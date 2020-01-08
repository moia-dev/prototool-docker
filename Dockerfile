# Swift plugin
FROM swift:5.1 as swift-plugin

ENV SWIFT_VERSION "1.7.0"

RUN apt-get -q update && \
    apt-get -q install -y \
    unzip curl \
    && rm -r /var/lib/apt/lists/*

RUN curl -L -o plugin.zip https://github.com/apple/swift-protobuf/archive/$SWIFT_VERSION.zip && \
  unzip plugin.zip -d ./plugin && \
  cd plugin/swift-protobuf-$SWIFT_VERSION && swift build --static-swift-stdlib -c release

RUN cp plugin/swift-protobuf-$SWIFT_VERSION/.build/x86_64-unknown-linux/release/protoc-gen-swift /usr/local/bin/protoc-gen-swift

# Kotlin plugin
FROM ubuntu:16.04 as kotlin-plugin

ENV KOTLIN_VERSION "0.3.0"

RUN apt-get update && \
    apt-get -y install curl zip
RUN curl -LO https://github.com/cretz/pb-and-k/releases/download/v$KOTLIN_VERSION/protoc-gen-kotlin-$KOTLIN_VERSION.zip && unzip -o protoc-gen-kotlin-$KOTLIN_VERSION.zip

RUN mkdir -p ./protoc-gen-kotlin/bin/ ./protoc-gen-kotlin/lib/
RUN cp -r ./protoc-gen-kotlin-$KOTLIN_VERSION/bin/ ./protoc-gen-kotlin/
RUN cp -r ./protoc-gen-kotlin-$KOTLIN_VERSION/lib/ ./protoc-gen-kotlin/


# Go plugin
FROM golang:1.13 as go-plugin

RUN go get github.com/golang/protobuf/protoc-gen-go
RUN go build -o /usr/local/bin/protoc-gen-go github.com/golang/protobuf/protoc-gen-go


# Scala plugin
FROM ubuntu:16.04 as scala-plugin

ENV SCALA_VERSION "0.9.6"

RUN apt-get update && \
    apt-get -y install curl zip

RUN curl -LO https://github.com/scalapb/ScalaPB/releases/download/v$SCALA_VERSION/protoc-gen-scala-$SCALA_VERSION-linux-x86_64.zip && unzip -o protoc-gen-scala-$SCALA_VERSION-linux-x86_64.zip
RUN cp ./protoc-gen-scala /usr/local/bin/


# Final builder
FROM uber/prototool as builder

RUN apk add --update --no-cache make openjdk8-jre && \
  rm -rf /var/cache/apk/*

COPY --from=swift-plugin /usr/local/bin/protoc-gen-swift /usr/local/bin/
COPY --from=kotlin-plugin ./protoc-gen-kotlin/bin/protoc-gen-kotlin /usr/local/bin
COPY --from=kotlin-plugin ./protoc-gen-kotlin/bin/protoc-gen-kotlin.bat /usr/local/bin
COPY --from=kotlin-plugin ./protoc-gen-kotlin/lib /usr/local/lib/
COPY --from=go-plugin /usr/local/bin/protoc-gen-go /usr/local/bin/
COPY --from=scala-plugin /usr/local/bin/protoc-gen-scala /usr/local/bin/
