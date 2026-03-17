from . import efectivo
from flask import render_template

@efectivo.route("/salida-efectivo")
def index_salida_efectivo():
    return render_template("efectivo/salidaEfectivo.html")

