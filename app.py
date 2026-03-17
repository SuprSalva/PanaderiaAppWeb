from flask import Flask, render_template, request, redirect, url_for, flash
from flask_wtf.csrf import CSRFProtect
from config import DevelopmentConfig
from models import db, Usuario
from werkzeug.security import generate_password_hash
from flask_migrate import Migrate 
import forms

from compras.routes import compras
from proveedores.routes import proveedores
from recetas.routes import recetas
from produccion.routes import produccion
from productoTerminado.routes import productoTerminado
from ventas.routes import ventas
from efectivo.routes import efectivo
from costoUtilidad.routes import costoUtilidad
from usuarios.routes import registrar_usuario_bp


app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect()
app.register_blueprint(compras)
app.register_blueprint(proveedores)
app.register_blueprint(recetas)
app.register_blueprint(produccion)
app.register_blueprint(productoTerminado)
app.register_blueprint(ventas)
app.register_blueprint(efectivo)
app.register_blueprint(costoUtilidad)
app.register_blueprint(registrar_usuario_bp)

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

@app.route("/", methods=['GET', 'POST'])
def entrar():
    form = forms.LoginForm(request.form)
    if request.method == 'POST' and form.validate():
        return redirect(url_for('dashboard'))
    return render_template("login.html", form=form)

@app.route("/login", methods=['GET', 'POST'])
def login():
    form = forms.LoginForm(request.form)
    if request.method == 'POST' and form.validate():
        return redirect(url_for('dashboard'))
    return render_template("login.html", form=form)

@app.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

@app.route("/dashboardVentas")
def dashboard_ventas():
    return render_template("dashboardVentas.html")

@app.route("/usuarios/registrar", methods=['GET', 'POST'])
def registrar_usuario():
    form = forms.RegistroUsuarioForm(request.form)
    
    if request.method == 'POST' and form.validate():
        hashed_password = generate_password_hash(form.password.data)
        
        nuevo_usuario = Usuario(
            nombre=form.nombre.data,
            username=form.usuario.data,
            password_hash=hashed_password,
            id_rol=form.rol.data,
            estatus='activo'
        )
        
        try:
            db.session.add(nuevo_usuario)
            db.session.commit()
            flash("Usuario registrado exitosamente")
            return redirect(url_for('dashboard'))
        except Exception as e:
            db.session.rollback()
            flash("Error: El nombre de usuario ya existe")
            
    return render_template("usuarios/registrar.html", form=form)

db.init_app(app)
migrate = Migrate(app, db) 

if __name__ == '__main__':
    csrf.init_app(app)
    with app.app_context():
        db.create_all() 
    app.run()