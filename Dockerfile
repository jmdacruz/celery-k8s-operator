FROM python:3.7
ADD Pipfile /src/Pipfile
ADD Pipfile.lock /src/Pipfile.lock
ADD handlers.py /src/handlers.py
WORKDIR /src
RUN pip install pipenv
RUN pipenv install --deploy --system
CMD kopf run handlers.py