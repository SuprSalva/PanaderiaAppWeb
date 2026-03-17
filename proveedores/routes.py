from flask import render_template
from . import proveedores 

@proveedores.route("/proveedores")
def index_proveedores():
    return render_template("proveedores/proveedores.html")

@proveedores.route("/materias-primas")
def materias_primas():          
    return render_template("proveedores/materiasPrimas/materiasPrimas.html")