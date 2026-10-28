FROM python:3.12-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# CPU-only torch first, so the project install does not pull the CUDA wheels.
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu
COPY pyproject.toml README.md LICENSE ./
COPY bsgen ./bsgen
COPY scripts ./scripts
RUN pip install --no-cache-dir -e .

# Bake the released models in so the container never needs Hugging Face.
ENV HF_HOME=/app/hf
RUN python -c "from bsgen import hub; hub.map_model(); hub.player_model(); hub.timing_model()" \
 && chmod -R a+rX /app/hf

ENV HF_HUB_OFFLINE=1 \
    GRADIO_ANALYTICS_ENABLED=False \
    GRADIO_TEMP_DIR=/tmp/gradio \
    NUMBA_CACHE_DIR=/tmp/numba \
    MPLCONFIGDIR=/tmp/mpl \
    HOME=/tmp \
    PYTHONUNBUFFERED=1

USER 65534:65534
EXPOSE 7860
CMD ["python", "scripts/webui.py", "--host", "0.0.0.0", "--port", "7860", "--device", "cpu"]
