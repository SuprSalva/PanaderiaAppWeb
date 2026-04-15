from flask import Blueprint

ventas = Blueprint(
    'ventas', 
    __name__, 
    template_folder='templates',
    static_folder='static',
    url_prefix='/ventas' 
)

from . import routes
