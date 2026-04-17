FROM python:3.11-slim

WORKDIR /app

COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app/app.py /app/app.py

RUN mkdir -p /app/logs /app/config

EXPOSE 8080

CMD ["python", "/app/app.py"]