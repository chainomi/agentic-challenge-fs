# Debian-based (glibc) node:15, not alpine: node-sass@5 ships a prebuilt glibc
# binary for Node 15 but none for Alpine's musl, and the alpine image has no
# compiler toolchain to build it from source — npm install would fail there.
FROM node:15 AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM nginx:1.21-alpine

COPY --from=build /app/build /usr/share/nginx/html
# nginx.conf holds a bare server{} block, so it must be included from inside the
# stock http{} context. Place it as a conf.d drop-in (this also overrides the
# image's default server). Copying it over /etc/nginx/nginx.conf would put a
# server{} at the top level and nginx would refuse to start.
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
