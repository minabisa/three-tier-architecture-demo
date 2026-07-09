# ---- Build stage: has npm, installs dependencies ----

FROM node:22-bookworm-slim AS build

WORKDIR /opt/server

COPY package.json /opt/server/

RUN npm install --omit=dev

COPY server.js /opt/server/

# ---- Runtime stage: no npm, no shell, minimal attack surface ----

FROM gcr.io/distroless/nodejs22-debian12

ENV INSTANA_AUTO_PROFILE=true

WORKDIR /opt/server

COPY --from=build /opt/server /opt/server

EXPOSE 8080

CMD ["server.js"]
