from . import recetas
from flask import render_template

@recetas.route("/recetas")
def index_recetas():
    return render_template("recetas/recetas.html")
