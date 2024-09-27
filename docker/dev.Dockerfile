# Stage 1: Use the official allora-offchain-node image to extract the binary
FROM --platform=linux/amd64 alloranetwork/allora-offchain-node:v0.4.0 AS allora_node

# Stage 2: Use the official Python 3.9 slim image for the allora-worker
FROM python:3.9-slim

# Install cron, curl, and supervisor
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    build-essential \
    gcc \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy requirements.txt into the working directory
COPY ./src/requirements.txt /app/requirements.txt


# Upgrade pip and install Cython and numpy manually by parsing the requirements.txt
# they are known nuisances with the pip install -r requirements.txt
RUN pip install --upgrade pip && \
    CYTHON_VERSION=$(grep -i '^Cython==' /app/requirements.txt | cut -d'=' -f3) \
    && NUMPY_VERSION=$(grep -i '^numpy==' /app/requirements.txt | cut -d'=' -f3) \
    && pip install --no-cache-dir Cython==$CYTHON_VERSION numpy==$NUMPY_VERSION

# Install requirements.txt
RUN pip install --no-cache-dir -r requirements.txt --timeout 1000

# Copy the allora-offchain-node binary from the first stage
COPY --from=allora_node /node/allora_offchain_node /usr/local/bin/allora_offchain_node
# Copy the allonode-data .env file
COPY ./allonode-data/.env /node/.env

# Expose the port that the app will run on
EXPOSE 8000

# Start services
CMD ["sh", "-c", "crontab /app/settings/crontab && cron && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"]
