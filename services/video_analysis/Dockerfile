FROM python:3.11-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV ARTIFACT_ROOT=/data/analysis_artifacts \
    JOB_STORE_PATH=/data/analysis_artifacts/jobs.json \
    ENGINE_VERSION=elote-0.1.0

RUN mkdir -p /data/analysis_artifacts

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
