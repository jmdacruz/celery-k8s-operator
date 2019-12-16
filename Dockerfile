FROM python:3.7.5-alpine3.10 as build
RUN apk add alpine-sdk
RUN pip install pipenv
ADD Pipfile /src/Pipfile
ADD Pipfile.lock /src/Pipfile.lock
WORKDIR /src
RUN pipenv lock -r > reqs.txt
RUN pip wheel -r reqs.txt


FROM python:3.7.5-alpine3.10
COPY --from=build /src/*.whl /wheels/
RUN pip install /wheels/*.whl
ADD handlers.py /src/handlers.py
WORKDIR /src
CMD kopf run handlers.py