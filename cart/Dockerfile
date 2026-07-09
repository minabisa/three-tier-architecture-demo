FROM node:22-bookworm-slim AS build

WORKDIR /opt/server

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY server.js .

# ---- Runtime stage ----
FROM gcr.io/distroless/nodejs22-debian12:nonroot

ENV INSTANA_AUTO_PROFILE=true

WORKDIR /opt/server

COPY --from=build --chown=nonroot:nonroot /opt/server /opt/server

EXPOSE 8080

USER nonroot

CMD ["server.js"]
