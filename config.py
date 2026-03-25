import os

# ─── Cadena base ───────────────────────────────────────────────────────────
_BASE = 'mysql+pymysql://{user}:{pwd}@127.0.0.1/dulce_migaja'

# ─── URI del ORM (solo lectura — consultas del modelo SQLAlchemy) ──────────
_WEB_URI = _BASE.format(user='web_user', pwd='123')

# ─── URIs por rol de BD (para ejecutar SPs con los permisos correctos) ─────
#  Cada clave_rol del sistema mapea a un usuario de MySQL con sus permisos.
DB_ROLE_URIS = {
    'admin':    _BASE.format(user='dm_admin',    pwd='Dm@Admin2025!'),
    'vendedor': _BASE.format(user='dm_vendedor', pwd='Dm@Vend2025!'),
    'panadero': _BASE.format(user='dm_panadero', pwd='Dm@Pan2025!'),
    'cliente':  _BASE.format(user='dm_cliente',  pwd='Dm@Cli2025!'),
    # Usuario de solo-lectura para verificar la tabla de usuarios
    'readonly': _BASE.format(user='dm_readonly', pwd='Dm@Read2025!'),
}


class Config(object):
    SECRET_KEY = "DulceMigajaSecretKey"
    SESSION_COOKIE_SECURE = False


class DevelopmentConfig(Config):
    DEBUG = True
    # ORM usa web_user para todas las lecturas del modelo
    SQLALCHEMY_DATABASE_URI = _WEB_URI
    SQLALCHEMY_TRACK_MODIFICATIONS = False
