# BB-Terminal — multi-stage build
# Stage 1: build the Vite frontend
FROM node:20-bookworm-slim AS ui-builder
WORKDIR /work
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/vaughanf1/BB-Terminal.git /work/src
WORKDIR /work/src/app
RUN npm install --no-audit --no-fund

# Stage 2: runtime — Python OpenBB API + Vite preview server
FROM python:3.12-slim-bookworm AS runtime
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NODE_VERSION=20
WORKDIR /app

# install node + system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# clone BB-Terminal source (use git so we get a clean tree)
RUN git clone --depth 1 https://github.com/vaughanf1/BB-Terminal.git /app/src
WORKDIR /app/src

# install OpenBB platform + its providers (this is the heavy step ~3 min)
RUN pip install --upgrade pip && pip install openbb openbb-api uvicorn fastapi

# bring over node_modules from builder
COPY --from=ui-builder /work/src/app/node_modules /app/src/app/node_modules

# expose API + UI ports
EXPOSE 6900 5173

# write a small entrypoint that launches API + Vite preview in parallel
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
