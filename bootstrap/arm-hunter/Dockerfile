FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir flask oci-cli

COPY app.py .
COPY templates/ templates/

EXPOSE 5000

CMD ["python", "app.py"]
