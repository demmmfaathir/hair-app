FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TF_CPP_MIN_LOG_LEVEL=2 \
    USE_TF=0

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --default-timeout=300 --retries 10 tensorflow==2.21.0
RUN pip install --no-cache-dir --default-timeout=300 --retries 10 -r requirements.txt

# unduh model CLIP saat build, supaya container tidak perlu internet saat dijalankan
RUN python -c "from transformers import CLIPModel, CLIPProcessor; CLIPModel.from_pretrained('openai/clip-vit-base-patch32'); CLIPProcessor.from_pretrained('openai/clip-vit-base-patch32')"
ENV HF_HUB_OFFLINE=1

COPY main.py rules.py ./
COPY model ./model

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]