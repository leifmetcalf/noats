FROM docker.io/apify/actor-node-playwright-chrome:20 AS builder

# Copy just package.json and package-lock.json
# to speed up the build using Docker layer cache.
COPY --chown=myuser package*.json ./

RUN npm install --include=dev

COPY --chown=myuser . ./

RUN npm run build

FROM docker.io/apify/actor-node-playwright-chrome:20

COPY --from=builder --chown=myuser /home/myuser/src/main.js ./main.js

# Copy just package.json and package-lock.json
# to speed up the build using Docker layer cache.
COPY --chown=myuser package*.json ./

RUN npm install --omit=dev

COPY --chown=myuser . ./

CMD ["./new_xvfb_run_cmd.sh", "node", "main.js"]
