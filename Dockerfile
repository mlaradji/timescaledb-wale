# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM bitnami/wal-g:latest

# Fix from https://stackoverflow.com/a/57930100/9954163.
USER root
RUN apt-get update && apt-get install python3.7 pipenv -y
USER 1001

# Install build dependencies.
USER root
RUN apt-get install python3.7-dev libffi-dev gcc musl-dev make libc-dev -y

# Install api dependencies.
RUN mkdir /app/ 
WORKDIR /app/
ENV PIPENV_VENV_IN_PROJECT=true
COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy --ignore-pipfile --system
RUN chown -R 1001 /app/

# Remove unneeded dependencies.
USER root
RUN apt-get purge python3.7-dev libffi-dev gcc musl-dev make libc-dev -y && \
    apt-get autoremove -y && apt-get clean -y

USER 1001
WORKDIR /app/

COPY src/wale-rest.py .
COPY run.sh .

ENTRYPOINT [ "/app/run.sh" ]

# Add a healthcheck.
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8000/ping || exit 1