from flask import Blueprint

registrar_usuario_bp = Blueprint(  
    'registrar_usuario',
    __name__,
    template_folder='templates',
    static_folder='static'
)
from . import routes