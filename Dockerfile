FROM python:3.10-slim

RUN apt-get install -y \
    gfortran \
    make \

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x pipeline.sh

CMD ["./pipeline.sh"]