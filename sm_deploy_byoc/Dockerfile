FROM python:3.7-slim

WORKDIR /app

COPY requirements.txt /app/
RUN pip install -r requirements.txt

RUN apt-get update && apt-get install -y \
    default-jdk \
    g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
COPY open-korean-text-2.1.0.jar /usr/local/lib/python3.7/site-packages/konlpy/java/
RUN cd /usr/local/lib/python3.7/site-packages/konlpy/java/ && \
    jar xvf open-korean-text-2.1.0.jar

COPY serve ./
RUN chmod +x serve
COPY inference.py ./

ENTRYPOINT ["python", "serve"]
