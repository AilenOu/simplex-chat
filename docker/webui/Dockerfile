ARG TAG=22.04

FROM ubuntu:${TAG} AS build

RUN apt-get update && apt-get install -y curl git build-essential libgmp3-dev zlib1g-dev llvm-12 llvm-12-dev libnuma-dev libssl-dev

ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.6.3
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.1.0

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:$PATH"

RUN ghcup set ghc "${BOOTSTRAP_HASKELL_GHC_VERSION}" && ghcup set cabal "${BOOTSTRAP_HASKELL_CABAL_VERSION}"

COPY . /project
WORKDIR /project

RUN cp ./scripts/cabal.project.local.linux ./cabal.project.local
RUN cabal update
# Build with a single job to avoid OOM/worker crashes in Docker Desktop.
RUN cabal build -j1 exe:simplex-chat --constraint 'simplexmq +client_library' --constraint 'simplex-chat -client_library'
RUN bin=$(find /project/dist-newstyle -name "simplex-chat" -type f -executable) && mv "$bin" /usr/local/bin/simplex-chat && strip /usr/local/bin/simplex-chat

FROM ubuntu:${TAG}

RUN apt-get update && apt-get install -y nginx ca-certificates bash tini && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin/simplex-chat /usr/local/bin/simplex-chat
COPY webui /opt/simplex-webui
COPY docker/webui/nginx.conf /etc/nginx/nginx.conf
COPY docker/webui/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV SIMPLEX_WS_PORT=5225
ENV SIMPLEX_DB_PATH=/var/lib/simplex/chat

VOLUME ["/var/lib/simplex"]
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
