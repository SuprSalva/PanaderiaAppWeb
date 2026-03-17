from . import productoTerminado
from flask import render_template

@productoTerminado.route("/producto-terminado")
def index_producto_terminado():
    return render_template("productoTerminado/productoTerminado.html")