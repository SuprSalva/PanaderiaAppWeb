from flask import Blueprint

costoUtilidad = Blueprint(
    'costoUtilidad',
    __name__,
    template_folder='templates',
    static_folder='static'
)

from . import routes