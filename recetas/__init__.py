from flask import Blueprint

recetas_bp = Blueprint(
    'recetas_bp',
    __name__,
    template_folder='templates',
    static_folder='static'
)

from . import routes