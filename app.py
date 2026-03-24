import uuid
import datetime

from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_wtf.csrf import CSRFProtect
from config import DevelopmentConfig
from models import db, Usuario, Rol
from werkzeug.security import generate_password_hash, check_password_hash
from flask_migrate import Migrate
from functools import wraps
import forms

from compras.routes import compras
from proveedores.routes import proveedores
from recetas.routes import recetas_bp
from produccion.routes import produccion
from productoTerminado.routes import productoTerminado
from ventas.routes import ventas
from efectivo.routes import efectivo
from costoUtilidad.routes import costoUtilidad
from usuarios.routes import registrar_usuario_bp
from productos.routes import productos_bp

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect()

app.register_blueprint(compras)
app.register_blueprint(proveedores)
app.register_blueprint(recetas_bp)
app.register_blueprint(produccion)
app.register_blueprint(productoTerminado)
app.register_blueprint(ventas)
app.register_blueprint(efectivo)
app.register_blueprint(costoUtilidad)
app.register_blueprint(registrar_usuario_bp)
app.register_blueprint(productos_bp)

db.init_app(app)
migrate = Migrate(app, db)

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'usuario_id' not in session:
            flash('Debes iniciar sesión para acceder.')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

@app.route("/", methods=['GET', 'POST'])
@app.route("/login", methods=['GET', 'POST'])
def login():
    if 'usuario_id' in session:
        return redirect(url_for('dashboard'))

    form = forms.LoginForm(request.form)

    if request.method == 'POST' and form.validate():
        usuario = Usuario.query.filter_by(username=form.usuario.data).first()

        if usuario and check_password_hash(usuario.password_hash, form.password.data):
            if usuario.estatus != 'activo':
                flash('Tu cuenta está inactiva o bloqueada. Contacta al administrador.')
                return render_template("login.html", form=form)

            session['usuario_id']     = usuario.id_usuario         
            session['usuario_nombre'] = usuario.nombre_completo    
            session['usuario_user']   = usuario.username
            session['usuario_rol']    = usuario.rol.nombre_rol if usuario.rol else ''

            usuario.ultimo_login = datetime.datetime.now()
            db.session.commit()

            return redirect(url_for('dashboard'))
        else:
            flash('Usuario o contraseña incorrectos.')

    return render_template("login.html", form=form)

@app.route("/logout")
def logout():
    session.clear()
    flash('Sesión cerrada correctamente.')
    return redirect(url_for('login'))

@app.route("/usuarios/registrar", methods=['GET', 'POST'])
def registrar_usuario():
    form = forms.RegistroUsuarioForm(request.form)

    if request.method == 'POST' and form.validate():
        if Usuario.query.filter_by(username=form.usuario.data).first():
            flash('El nombre de usuario ya está en uso. Elige otro.')
            return render_template("usuarios/registrar.html", form=form)

        rol = Rol.query.filter_by(clave_rol=form.rol.data).first()
        if not rol:
            flash('El rol seleccionado no es válido.')
            return render_template("usuarios/registrar.html", form=form)

        nuevo_usuario = Usuario(
            uuid_usuario    = str(uuid.uuid4()),  
            nombre_completo = form.nombre.data,    
            username        = form.usuario.data,
            password_hash   = generate_password_hash(form.password.data),
            id_rol          = rol.id_rol,        
            estatus         = 'activo',
        )

        try:
            db.session.add(nuevo_usuario)
            db.session.commit()
            flash('Usuario registrado exitosamente. Ya puedes iniciar sesión.')
            return redirect(url_for('login'))
        except Exception as e:
            db.session.rollback()
            flash('Ocurrió un error al registrar. Intenta de nuevo.')

    return render_template("usuarios/registrar.html", form=form)

@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")

@app.route("/dashboardVentas")
@login_required
def dashboard_ventas():
    return render_template("dashboardVentas.html")

@app.route("/usuarios")
@login_required
def usuarios():
    return render_template("usuarios/usuarios.html")

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404


if __name__ == '__main__':
    csrf.init_app(app)
    with app.app_context():
        db.create_all()
    app.run(debug=True)