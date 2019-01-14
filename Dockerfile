# ================
# Build Stage
# ================

FROM qixxit/elixir-centos as build
MAINTAINER Ettore Berardi <ettore.berardi@bbc.co.uk>

ENV MIX_ENV=prod
ENV PORT=8080

COPY . .

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

RUN APP_NAME="origin_simulator" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    cp "$RELEASE_DIR/$APP_NAME.tar.gz" /export

# ================
# Deployment Stage
#
# For now just copying origin_simulator.tar.gz to the mounted host directory
# docker run --mount=source=/my/abs/path/to/build,target=/build,type=bind -it origin_simulator
# ================

FROM qixxit/elixir-centos
COPY --from=build /export /export
CMD ["cp", "/export/origin_simulator.tar.gz", "/build" ]
