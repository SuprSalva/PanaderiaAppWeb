from . import costoUtilidad
from flask import render_template


@costoUtilidad.route("/costoUtilidad")
def index_costo_utilidad():
    return render_template("costoUtilidad/costoUtilidad.html")

@costoUtilidad.route("/utilidad")
def index_utilidad():
    return render_template("costoUtilidad/utilidad.html")