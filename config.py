import os
from urllib.parse import quote_plus

# ─── Cadena base ───────────────────────────────────────────────────────────
_BASE = 'mysql+pymysql://{user}:{pwd}@127.0.0.1/dulce_migaja'

def _uri(user, pwd):
    return _BASE.format(user=user, pwd=quote_plus(pwd))

# ─── URI del ORM (solo lectura — consultas del modelo SQLAlchemy) ──────────
_WEB_URI = _uri('web_user', '123')

# ─── URIs por rol de BD (para ejecutar SPs con los permisos correctos) ─────
#  Cada clave_rol del sistema mapea a un usuario de MySQL con sus permisos.
DB_ROLE_URIS = {
    'admin':    _uri('dm_admin',    'Dm@Admin2025!'),
    'empleado': _uri('dm_vendedor', 'Dm@Vend2025!'),
    'panadero': _uri('dm_panadero', 'Dm@Pan2025!'),
    'cliente':  _uri('dm_cliente',  'Dm@Cli2025!'),
    'readonly': _uri('web_user',    '123'),
}

# Nombre del rol de BD que debe activarse con SET ROLE para cada clave_rol de app
DB_ROLE_NAMES = {
    'admin':    'rol_admin',
    'empleado': 'rol_vendedor',
    'panadero': 'rol_panadero',
    'cliente':  'rol_cliente',
    'readonly': None,
}


class Config(object):
    SECRET_KEY = "DulceMigajaSecretKey"
    SESSION_COOKIE_SECURE = False


class DevelopmentConfig(Config):
    DEBUG = True
    # ORM usa web_user para todas las lecturas del modelo
    SQLALCHEMY_DATABASE_URI = _WEB_URI
    SQLALCHEMY_TRACK_MODIFICATIONS = False
