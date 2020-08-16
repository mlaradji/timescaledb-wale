# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM bitnami/wal-g:latest
USER root

RUN mkdir /app/ 
WORKDIR /app/

# Fix from https://stackoverflow.com/a/57930100/9954163.
RUN apt-get update && apt-get install python3.7 pipenv -y

# Install build dependencies.
RUN apt-get install python3.7-dev libffi-dev gcc musl-dev make libc-dev -y

# Install api dependencies.
COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy --ignore-pipfile --system

# Remove unneeded dependencies.
RUN apt-get purge python3.7-dev libffi-dev gcc musl-dev make libc-dev -y && \
    apt-get autoremove -y && apt-get clean -y

COPY src/walg-rest.py ./
COPY entrypoint.sh ./

ENTRYPOINT [ "./entrypoint.sh" ]

# Add a healthcheck.
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8000/ping || exit 1