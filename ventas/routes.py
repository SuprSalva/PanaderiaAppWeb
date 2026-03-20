from . import ventas
from flask import render_template

@ventas.route("/ventas")
def index_ventas():
    return render_template("ventas/ventas.html")

@ventas.route("/corte-ventas")
def corte_ventas():
    return render_template("ventas/corteVentas.html")

@ventas.route("/ventas-online")
def ventas_online():
    return render_template("ventas/ventas-online.html")

@ventas.route("/checkout")
def checkout():
    return render_template("ventas/checkout.html")