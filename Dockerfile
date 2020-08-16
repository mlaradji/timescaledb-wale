# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM bitnami/wal-g:latest

# Install api dependencies.
COPY Pipfile Pipfile.lock ./

# Fix from https://stackoverflow.com/a/57930100/9954163.
USER root
RUN apt-get update && apt-get install python3.8 pipenv
USER 1001

# Install build dependencies.
USER root
RUN apt-get install python3-dev libffi-dev gcc musl-dev make libc-dev lzo-dev -y

# Install python dependencies.
USER 1001
RUN pipenv install --deploy --ignore-pipfile

# Remove unneeded dependencies.
USER root
RUN apt-get purge python3-dev libffi-dev gcc musl-dev make libc-dev lzo-dev -y && \
    apt-get autoremove -y && apt-get clean -y
USER 1001

COPY src/wale-rest.py .
COPY run.sh /

CMD [ "/run.sh" ]

# Add a healthcheck.
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:80/ping || exit 1