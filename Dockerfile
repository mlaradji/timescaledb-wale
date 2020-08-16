# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM bitnami/wal-g:latest

# Install api dependencies.
COPY Pipfile Pipfile.lock ./
RUN apt-get update && apt-get install python3.8 pipenv python3-dev libffi-dev gcc musl-dev make libc-dev lzo-dev -y &&\
    pipenv install --deploy --ignore-pipfile && \
    apt-get purge python3-dev libffi-dev gcc musl-dev make libc-dev lzo-dev -y && \
    apt-get autoremove -y && apt-get clean -y

COPY src/wale-rest.py .
COPY run.sh /

CMD [ "/run.sh" ]

# Add a healthcheck.
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:80/ping || exit 1