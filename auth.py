# auth.py — Decoradores de autorización por rol
from functools import wraps
from flask import abort
from flask_login import current_user


def roles_required(*roles):
    """
    Restringe una ruta a uno o más roles de la aplicación.

    Uso:
        @roles_required('admin')
        @roles_required('admin', 'vendedor')

    Si el usuario no está autenticado → 401
    Si el usuario no tiene el rol necesario → 403 (página de acceso denegado)
    """
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            if not current_user.is_authenticated:
                abort(401)
            clave = current_user.rol.clave_rol if current_user.rol else ''
            if clave not in roles:
                abort(403)
            return f(*args, **kwargs)
        return wrapper
    return decorator
