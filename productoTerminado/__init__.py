from flask import Blueprint

productoTerminado=Blueprint(
    'productoTerminado',
    __name__,
    template_folder='templates',
    static_folder='static')
from . import routes