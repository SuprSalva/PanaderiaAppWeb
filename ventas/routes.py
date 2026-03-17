from . import ventas
from flask import render_template

@ventas.route("/ventas")
def index_ventas():
    return render_template("ventas/ventas.html")

@ventas.route("/corte-ventas")
def corte_ventas():
    return render_template("ventas/corteVentas.html")

