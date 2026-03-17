from . import compras
from flask import render_template
from models import db , Compra

@compras.route("/compras")
def index_compras():
    return render_template("compras/compras.html")