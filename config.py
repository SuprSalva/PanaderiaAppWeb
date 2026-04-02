import os
from urllib.parse import quote_plus

_BASE = 'mysql+pymysql://{user}:{pwd}@127.0.0.1/dulce_migaja'

def _uri(user, pwd):
    return _BASE.format(user=user, pwd=quote_plus(pwd))

_WEB_URI = _uri('dm_web_user', 'Xycjym-rirmyv-3nuwho')

DB_ROLE_URIS = {
    'admin':    _uri('dm_admin',    'Gujtuc-zitny5-gyskuv'),
    'empleado': _uri('dm_empleado', 'fomzoh-Poqcoz-0wytqe'),
    'panadero': _uri('dm_panadero', 'bIdfyq-vycfof-pivwo3'),
    'cliente':  _uri('dm_cliente',  'vixpam-jidjim-5geDto'),
    'readonly': _uri('dm_web_user',    'Xycjym-rirmyv-3nuwho'),
}

DB_ROLE_NAMES = {
    'admin':    'rol_admin',
    'empleado': 'rol_empleado',
    'panadero': 'rol_panadero',
    'cliente':  'rol_cliente',
    'readonly': None,
}


class Config(object):
    SECRET_KEY = "DulceMigajaSecretKey"
    SESSION_COOKIE_SECURE = False


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = _WEB_URI
    SQLALCHEMY_TRACK_MODIFICATIONS = False
