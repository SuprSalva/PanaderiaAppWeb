from flask import Blueprint

efectivo=Blueprint(
    'efectivo',
    __name__,
    template_folder='templates',
    static_folder='static')
from . import routes