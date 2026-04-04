from . import costoUtilidad
from flask import render_template
from flask_login import login_required, current_user
from auth import roles_required


@costoUtilidad.route("/costoUtilidad")
@login_required
@roles_required('admin')
def index_costo_utilidad():
    return render_template("costoUtilidad/costoUtilidad.html")

@costoUtilidad.route("/utilidad")
@login_required
@roles_required('admin')
def index_utilidad():
    return render_template("costoUtilidad/utilidad.html")