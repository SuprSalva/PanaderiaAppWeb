import uuid
import datetime

from flask import Flask, render_template, request, redirect, url_for, flash
from flask_wtf.csrf import CSRFProtect
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from config import DevelopmentConfig
from models import db, Usuario, Rol
from werkzeug.security import generate_password_hash, check_password_hash
from flask_migrate import Migrate
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
from pedidos import pedidos_bp

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect()

login_manager = LoginManager()
login_manager.login_view = 'login'
login_manager.login_message = 'Debes iniciar sesión para acceder.'

@login_manager.user_loader
def load_user(user_id):
    return db.session.get(Usuario, int(user_id))

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
app.register_blueprint(pedidos_bp)  

db.init_app(app)
login_manager.init_app(app)
migrate = Migrate(app, db)

@app.route("/", methods=['GET', 'POST'])
@app.route("/login", methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))

    form = forms.LoginForm(request.form)

    if request.method == 'POST' and form.validate():
        usuario = Usuario.query.filter_by(username=form.usuario.data).first()

        if usuario and check_password_hash(usuario.password_hash, form.password.data):
            if usuario.estatus != 'activo':
                flash('Tu cuenta está inactiva o bloqueada. Contacta al administrador.')
                return render_template("login.html", form=form)

            login_user(usuario)
            usuario.ultimo_login = datetime.datetime.now()
            db.session.commit()

            return redirect(url_for('dashboard'))
        else:
            flash('Usuario o contraseña incorrectos.')

    return render_template("login.html", form=form)

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash('Sesión cerrada correctamente.', 'success')
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
            creado_por      = current_user.id_usuario if current_user.is_authenticated else None,
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

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

@app.route("/debug/usuario-bd")
@login_required
def debug_usuario_bd():
    from utils.db_roles import get_role_engine
    from sqlalchemy import text
    engine = get_role_engine()
    with engine.connect() as conn:
        usuario_bd = conn.execute(text("SELECT CURRENT_USER()")).scalar()
        rol_usuario = current_user.rol.clave_rol if current_user.rol else 'sin rol'
    return f"Rol app: {rol_usuario} | Usuario BD: {usuario_bd}"

csrf.init_app(app)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)