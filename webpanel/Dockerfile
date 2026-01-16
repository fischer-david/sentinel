FROM oven/bun:alpine AS webpanel-builder

RUN apk add --no-cache protobuf protobuf-dev

WORKDIR /app

COPY common/proto ./common/proto
COPY webpanel/package.json webpanel/bun.lock* ./

RUN bun install

COPY webpanel .

RUN if [ -f "./generate-proto.sh" ]; then ./generate-proto.sh; fi

RUN bun run build

FROM node:18-alpine

WORKDIR /app

COPY --from=webpanel-builder /app/.next/standalone ./
COPY --from=webpanel-builder /app/.next/static ./.next/static
COPY --from=webpanel-builder /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]
