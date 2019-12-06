FROM python:3.7
ADD . /src
WORKDIR /src
RUN pip install pipenv
RUN pipenv install --deploy --system
CMD kopf run handlers.py