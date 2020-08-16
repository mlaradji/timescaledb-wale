# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM python:3.5-alpine

# Add run dependencies in its own layer
RUN apk add --no-cache --virtual .run-deps lzo curl pv postgresql-client

COPY Pipfile Pipfile.lock ./
RUN apk add --no-cache --virtual .build-deps python3-dev libffi-dev gcc musl-dev make libc-dev lzo-dev && \
    python3 -m pip install pipenv && pipenv install --deploy --ignore-pipfile && \
    apk del .build-deps

COPY src/wale-rest.py .
COPY run.sh /

CMD [ "/run.sh" ]

# Add a healthcheck.
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:80/ping || exit 1