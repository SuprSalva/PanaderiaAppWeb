# usuarios/routes.py
from flask import render_template
from . import registrar_usuario_bp

@registrar_usuario_bp.route("/usuarios")
def usuarios():
    return render_template("usuarios/usuarios.html")