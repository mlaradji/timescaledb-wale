#!/usr/bin/python

from subprocess import Popen
import sys
import logging
import logging.config
import os
from logging.config import dictConfig
import pydantic

from flask import Flask, request

class BaseSettingsConfig:
    case_sensitive = True

class Api(pydantic.BaseSettings):
    """Flask application settings."""
    HOST: str = '0.0.0.0'
    PORT: int = 8000

    class Config(BaseSettingsConfig):
        env_prefix = "API_"

class WalG(pydantic.BaseSettings):
    """
    `wal-g` binary parameters.
    """
    BIN: str = 'wal-g'
    FLAGS: str = ''
    PUSH_FLAGS: str = ''
    FETCH_FLAGS: str = '-p=0'

    class Config(BaseSettingsConfig):
        env_prefix: str = "WALG_"

class Postgres(pydantic.BaseSettings):
    """
    Postgres settings.
    """

    DATA: pydantic.DirectoryPath = '/var/lib/postgresql/data'
    WAL: pydantic.DirectoryPath = '/var/lib/postgresql/data/pg_wal'

    class Config(BaseSettingsConfig):
        env_prefix: str = "PG"

API = Api()
WALG = WalG()
PG = Postgres()

class WaleWrapper:

    api = None

    def __init__(self):

        self.api = Flask('RestAPI')

        log_conf = {
            'version': 1,
            'handlers': {
                'console': {
                    'class': 'logging.StreamHandler',
                    'stream': sys.stdout,
                }
            },
            'root': {
                'handlers': ['console'],
                'level': 'INFO'
            }
        }

        logging.config.dictConfig(log_conf)
        logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

        # create routes
        self.api.add_url_rule('/ping', view_func=self.ping, methods=['GET'])
        self.api.add_url_rule('/wal-push/<path:path>', view_func=self.push, methods=['GET'])
        self.api.add_url_rule('/wal-fetch/<path:path>', view_func=self.fetch, methods=['GET'])
        self.api.add_url_rule('/backup-push', view_func=self.backup_push, methods=['GET'])

        self.api.logger.info('Ready to receive wal-e commands')

        # start API
        self.api.run(host=API.HOST, port=API.PORT, debug=False, threaded=True)

    def perform_command(self, cmd, log_line, error_line, return_line):

        self.api.logger.info('{}: {}'.format(log_line, cmd))

        p = Popen(cmd)
        outs, errs = p.communicate()

        if p.returncode != 0:
            self.api.logger.error(error_line + ': ' + str(errs))
            return errs, 500

        return return_line

    def push(self, path):

        if '/' in path:
            path = path.split('/')[-1]

        file_path = PG.WAL + '/' + path

        command = [WALG.BIN]
        if len(WALG.FLAGS) > 0:
            for s in WALG.FLAGS.split():
                command.append(s)
        command.append('wal-push')
        if len(WALG.PUSH_FLAGS) > 0:
            for s in WALG.PUSH_FLAGS.split():
                command.append(s)
        command.extend([file_path])
        print(command)

        return self.perform_command(command,
                                    'Pushing wal file {}'.format(file_path),
                                    'Failed to push wal {}'.format(file_path),
                                    'Pushed wal {}'.format(file_path))

    def fetch(self, path):

        if '/' in path:
            path = path.split('/')[-1]

        file_id = path

        file_path  = PG.WAL + '/' + file_id

        command = [WALG.BIN]
        if len(WALG.FLAGS) > 0:
            for s in WALG.FLAGS.split():
                command.append(s)
        command.append('wal-fetch')
        if len(WALG.FETCH_FLAGS) > 0:
            for s in WALG.FETCH_FLAGS.split():
                command.append(s)
        command.extend([file_id, file_path])
        print(command)

        return self.perform_command(command,
                                    'Fetching wal {}'.format(file_id),
                                    'Failed to fetch wal {}'.format(file_id),
                                    'Fetched wal {}'.format(file_id))

    def backup_push(self):
        file_path = PG.DATA
        command = [WALG.BIN]
        if len(WALG.FLAGS) > 0:
            for s in WALG.FLAGS.split():
                command.append(s)
        command.append('backup-push')
        if len(WALG.PUSH_FLAGS) > 0:
            for s in WALG.PUSH_FLAGS.split():
                command.append(s)
        command.extend([file_path])
        print(command)

        return self.perform_command(command,
                                    'Pushing backup {}'.format(file_path),
                                    'Failed to push backup {}'.format(file_path),
                                    'Pushed backup {}'.format(file_path))

    def ping(self):
        return 'pong'


if __name__ == '__main__':
    _ = WaleWrapper()
