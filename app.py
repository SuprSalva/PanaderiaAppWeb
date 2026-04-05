import uuid
import datetime
import logging

from flask import Flask, render_template, request, redirect, url_for, flash
from flask_wtf.csrf import CSRFProtect
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from config import DevelopmentConfig
from sqlalchemy import text
from models import db, Usuario, Rol
from werkzeug.security import generate_password_hash, check_password_hash
from flask_migrate import Migrate
import forms

from compras.routes import compras
from proveedores.routes import proveedores
from recetas.routes import recetas_bp
from produccion.routes import produccion
from ventas.routes import ventas
from efectivo.routes import efectivo
from costoUtilidad.routes import costoUtilidad
from usuarios.routes import registrar_usuario_bp
from productos.routes import productos_bp
from pedidos import pedidos_bp
from materiasPrimas.routes import materias_primas_bp

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect(app)

LOG_FILENAME = 'app.log'
logging.basicConfig(
    filename=LOG_FILENAME,
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

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
app.register_blueprint(ventas)
app.register_blueprint(efectivo)
app.register_blueprint(costoUtilidad)
app.register_blueprint(registrar_usuario_bp)
app.register_blueprint(productos_bp)
app.register_blueprint(pedidos_bp)  
app.register_blueprint(materias_primas_bp)

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
                app.logger.warning('Intento de acceso fallido (cuenta inactiva) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('Tu cuenta está inactiva o bloqueada. Contacta al administrador.', 'warning')
                return render_template("login.html", form=form)

            if usuario.rol and usuario.rol.clave_rol == 'cliente':
                app.logger.warning('Intento de acceso fallido (area incorrecta) | username: %s | rol: cliente | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('Esta área es exclusiva para empleados. Usa el acceso de clientes.', 'warning')
                return render_template("login.html", form=form)

            login_user(usuario)
            app.logger.info('Acceso exitoso | id: %s | username: %s | rol: %s | fecha: %s', usuario.id_usuario, usuario.username, usuario.rol.clave_rol if usuario.rol else 'N/A', datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            usuario.ultimo_login = datetime.datetime.now()
            db.session.commit()

            return redirect(url_for('dashboard'))
        else:
            app.logger.warning('Intento de acceso fallido (credenciales incorrectas) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Usuario o contraseña incorrectos.', 'error')

    return render_template("login.html", form=form)

@app.route("/logout")
@login_required
def logout():
    app.logger.info('Cierre de sesion | id: %s | username: %s | fecha: %s', current_user.id_usuario, current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    es_cliente = (current_user.rol.clave_rol == 'cliente') if current_user.rol else False
    logout_user()
    flash('Sesión cerrada correctamente.', 'success')
    return redirect(url_for('login_cliente' if es_cliente else 'login'))

@app.route("/cliente/login", methods=['GET', 'POST'])
def login_cliente():
    if current_user.is_authenticated:
        return redirect(url_for('pedidos.mis_pedidos'))

    form = forms.LoginForm(request.form)
    if request.method == 'POST' and form.validate():
        usuario = Usuario.query.filter_by(username=form.usuario.data).first()
        if usuario and check_password_hash(usuario.password_hash, form.password.data):
            if usuario.estatus != 'activo':
                app.logger.warning('Intento de acceso cliente fallido (cuenta inactiva) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('Tu cuenta está inactiva o bloqueada. Contacta al administrador.', 'error')
                return render_template("login_cliente.html", form=form)
            clave = usuario.rol.clave_rol if usuario.rol else ''
            if clave != 'cliente':
                app.logger.warning('Intento de acceso cliente fallido (area incorrecta) | username: %s | rol: %s | fecha: %s', form.usuario.data, clave, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('Esta área es exclusiva para clientes.', 'error')
                return render_template("login_cliente.html", form=form)
            login_user(usuario)
            app.logger.info('Acceso cliente exitoso | id: %s | username: %s | fecha: %s', usuario.id_usuario, usuario.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            usuario.ultimo_login = datetime.datetime.now()
            db.session.commit()
            return redirect(url_for('pedidos.mis_pedidos'))
        else:
            app.logger.warning('Intento de acceso cliente fallido (credenciales incorrectas) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Usuario o contraseña incorrectos.', 'error')

    return render_template("login_cliente.html", form=form)


@app.route("/cliente/registro", methods=['GET', 'POST'])
def registrar_cliente():
    if current_user.is_authenticated:
        return redirect(url_for('pedidos.mis_pedidos'))

    form = forms.RegistroClienteForm(request.form)
    if request.method == 'POST' and form.validate():
        try:
            db.session.execute(
                text("CALL sp_registrar_cliente(:uuid, :nombre, :telefono, :username, :pwd_hash)"),
                {
                    'uuid':     str(uuid.uuid4()),
                    'nombre':   form.nombre.data.strip(),
                    'telefono': form.telefono.data.strip(),
                    'username': form.username.data.strip(),
                    'pwd_hash': generate_password_hash(form.password.data),
                }
            )
            db.session.commit()
            app.logger.info('Nuevo cliente registrado | username: %s | nombre: %s | fecha: %s', form.username.data.strip(), form.nombre.data.strip(), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('¡Cuenta creada exitosamente! Ya puedes iniciar sesión.', 'success')
            return redirect(url_for('login_cliente'))
        except Exception as e:
            db.session.rollback()
            orig = getattr(e, 'orig', None)
            code = orig.args[0] if orig and hasattr(orig, 'args') and len(orig.args) >= 1 else None
            msg  = orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e)
            if code == 1062 or 'ya esta en uso' in msg or 'ya está en uso' in msg:
                app.logger.warning('Intento de registro cliente con usuario ya existente | username: %s | fecha: %s', form.username.data.strip(), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('El nombre de usuario ya está en uso. Elige otro.', 'error')
            else:
                app.logger.error('Error general al registrar cliente | username: %s | error: %s | fecha: %s', form.username.data.strip(), msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash(msg, 'error')

    return render_template("usuarios/registrar_cliente.html", form=form)


@app.route("/usuarios/registrar", methods=['GET', 'POST'])
def registrar_usuario():
    form = forms.RegistroUsuarioForm(request.form)

    if request.method == 'POST' and form.validate():
        if Usuario.query.filter_by(username=form.usuario.data).first():
            app.logger.warning('Intento de registro de usuario fallido (nombre ya en uso) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El nombre de usuario ya está en uso. Elige otro.', 'warning')
            return render_template("usuarios/registrar.html", form=form)

        rol = Rol.query.filter_by(clave_rol=form.rol.data).first()
        if not rol:
            app.logger.warning('Intento de registro de usuario fallido (rol invalido) | username: %s | rol_pedido: %s | fecha: %s', form.usuario.data, form.rol.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El rol seleccionado no es válido.', 'error')
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
            app.logger.info('Nuevo empleado registrado | username: %s | rol: %s | fecha: %s', form.usuario.data, rol.clave_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Usuario registrado exitosamente. Ya puedes iniciar sesión.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            db.session.rollback()
            app.logger.error('Error general al registrar empleado | username: %s | error: %s | fecha: %s', form.usuario.data, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Ocurrió un error al registrar. Intenta de nuevo.', 'error')

    return render_template("usuarios/registrar.html", form=form)

@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")

@app.route("/dashboardVentas")
@login_required
def dashboard_ventas():
    return render_template("dashboardVentas.html")

@app.errorhandler(403)
def forbidden(e):
    return render_template("403.html"), 403

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

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.logger.info('Aplicacion iniciada correctamente')
    app.run(debug=True)