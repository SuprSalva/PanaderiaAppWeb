# utils/db_roles.py
# ─────────────────────────────────────────────────────────────────────────────
#  Conexiones de BD por rol
#
#  Toda operación de escritura (SPs, INSERT, UPDATE) debe ejecutarse a través
#  de role_connection() o call_sp() para que la BD aplique los privilegios del
#  usuario MySQL correspondiente al rol del usuario autenticado.
#
#  El ORM (SQLAlchemy / db.session) con dm_web_user se reserva únicamente para
#  las consultas de modelo de Flask-Login (load_user, .query en auth).
#
#  NOTA MySQL 8: los roles de BD requieren SET ROLE en cada nueva conexión.
#  El event listener "connect" activa el rol automáticamente.
# ─────────────────────────────────────────────────────────────────────────────
from contextlib import contextmanager
from sqlalchemy import create_engine, event, text
from flask_login import current_user
from config import DB_ROLE_URIS, DB_ROLE_NAMES

# Cache de engines por rol (un engine por rol, reutilizado en toda la app)
_engines: dict = {}


def _make_engine(uri: str, rol_nombre: str | None):
    """Crea el engine y registra el evento que activa el rol al conectar."""
    engine = create_engine(uri, pool_size=3, max_overflow=5, pool_pre_ping=True)

    if rol_nombre:
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

    if clave_rol not in DB_ROLE_URIS:
        clave_rol = 'readonly'

    if clave_rol not in _engines:
        uri = DB_ROLE_URIS[clave_rol]
        rol_bd = DB_ROLE_NAMES.get(clave_rol)
        _engines[clave_rol] = _make_engine(uri, rol_bd)

    return _engines[clave_rol]


@contextmanager
def role_connection():
    """
    Context manager: abre una conexión con el engine del rol del usuario
    autenticado y la cierra (con rollback implícito si no hubo commit) al salir.

    Además inyecta @dm_user_id como variable de sesión MySQL para que los
    triggers de auditoría (bitacora) puedan registrar quién realizó la acción.

    Uso básico:
        with role_connection() as conn:
            conn.execute(text("CALL sp_..."), params)
            conn.commit()

    Uso con OUT variables (deben estar en la misma conexión):
        with role_connection() as conn:
            conn.execute(text("CALL sp_crear(:p, @id_out)"), params)
            conn.execute(text("COMMIT"))
            id_out = conn.execute(text("SELECT @id_out")).scalar()

    Uso con cursor raw (para callproc / múltiples result-sets):
        with role_connection() as conn:
            cur = conn.connection.cursor()
            cur.callproc('sp_nombre', (arg1, arg2))
            rows = cur.fetchall()
            cur.close()
            conn.commit()
    """
    engine = get_role_engine()
    with engine.connect() as conn:
        # Inyectar ID de usuario para triggers de auditoría (bitacora).
        # Se hace en cada apertura de contexto, no en el evento "connect",
        # para garantizar que el valor siempre corresponde a la sesión activa
        # y no al último usuario que usó esa conexión del pool.
        try:
            uid = current_user.id_usuario if current_user.is_authenticated else None
        except RuntimeError:
            uid = None  # fuera de contexto de request (scripts, tareas)
        conn.execute(text("SET @dm_user_id = :uid"), {'uid': uid})
        yield conn


def call_sp(sql: str, params: dict | None = None):
    """
    Ejecuta un stored procedure usando el usuario de BD del rol del usuario
    logueado. Lanza la excepción original para que la ruta pueda capturar
    el SIGNAL del SP y mostrar el mensaje correcto al usuario.
    """
    with role_connection() as conn:
        conn.execute(text(sql), params or {})
        conn.commit()
