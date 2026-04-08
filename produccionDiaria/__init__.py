from flask import Blueprint

produccion_diaria=Blueprint(
    'produccion_diaria',
    __name__,
    template_folder='templates',
    static_folder='static')
from . import routes