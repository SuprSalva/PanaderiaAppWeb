from flask import Blueprint
 
materias_primas_bp = Blueprint(
    'materias_primas',
    __name__,
    template_folder='templates',
    static_folder='static'
)
 
from . import routes