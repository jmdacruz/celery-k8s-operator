FROM python:3.7.5-alpine3.10 as celery-base

RUN pip install celery==4.3.0 ruamel-yaml==0.16.5 flower==0.9.3 redis
RUN mkdir /app
WORKDIR /app
ADD celeryconfig.py /app
CMD ["celery", "worker", "--config", "celeryconfig"]

FROM celery-base
ADD tasks.py /app
