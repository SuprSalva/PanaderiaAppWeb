from . import produccion
from flask import render_template

@produccion.route("/produccion-solicitud")
def index_produccion_solicitud():
    return render_template("produccion/solicitudes.html")

@produccion.route("/produccion")
def index_produccion():
    return render_template("produccion/produccion.html")