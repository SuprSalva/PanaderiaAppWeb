from flask import Blueprint

productos_bp = Blueprint(
    'productos_bp',
    __name__,
    template_folder='templates',
    static_folder='static'
)

from . import routes