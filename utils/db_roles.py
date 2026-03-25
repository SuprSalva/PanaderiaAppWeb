# utils/db_roles.py
# ─────────────────────────────────────────────────────────────────────────────
#  Conexiones de BD por rol
#
#  El ORM (SQLAlchemy / db.session) usa web_user para lecturas de modelos
#  y para los SPs de los otros módulos (compras, ventas, produccion, etc.).
#
#  Para los SPs del módulo de usuarios se usa el usuario de BD del rol
#  del usuario logueado (dm_admin, dm_vendedor, etc.) via call_sp().
#
#  NOTA MySQL 8: los roles de BD requieren SET ROLE en cada nueva conexión.
#  El event listener "connect" activa el rol automáticamente.
# ─────────────────────────────────────────────────────────────────────────────
from sqlalchemy import create_engine, event, text
from flask_login import current_user
from config import DB_ROLE_URIS

# Cache de engines por rol (un engine por rol, reutilizado en toda la app)
_engines: dict = {}


def _make_engine(uri: str, rol_nombre: str):
    """Crea el engine y registra el evento que activa el rol al conectar."""
    engine = create_engine(uri, pool_size=3, max_overflow=5, pool_pre_ping=True)

    # MySQL 8: activa el rol de BD en cada nueva conexión del pool
    @event.listens_for(engine, "connect")
    def activar_rol(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute(f"SET ROLE `{rol_nombre}`")
        cursor.close()

    return engine


def get_role_engine(clave_rol: str | None = None):
    """
    Devuelve un SQLAlchemy Engine para el rol indicado.
    Si no se pasa clave_rol, usa el rol del usuario logueado.
    Cae a 'readonly' si el rol no está mapeado.
    """
    if clave_rol is None:
        clave_rol = (
            current_user.rol.clave_rol
            if current_user.is_authenticated and current_user.rol
            else 'readonly'
        )

    if clave_rol not in _engines:
        uri = DB_ROLE_URIS.get(clave_rol, DB_ROLE_URIS['readonly'])
        # El nombre del rol de BD coincide con el patrón "rol_<clave>"
        rol_bd = f"rol_{clave_rol}"
        _engines[clave_rol] = _make_engine(uri, rol_bd)

    return _engines[clave_rol]


def call_sp(sql: str, params: dict | None = None):
    """
    Ejecuta un stored procedure usando el usuario de BD del rol del usuario
    logueado. Lanza la excepción original para que la ruta pueda capturar
    el SIGNAL del SP y mostrar el mensaje correcto al usuario.
    """
    engine = get_role_engine()
    with engine.connect() as conn:
        conn.execute(text(sql), params or {})
        conn.commit()
