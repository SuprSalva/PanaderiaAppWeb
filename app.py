import uuid
import datetime
import logging
import random
import time
import json
import urllib.request
import urllib.parse

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from flask_wtf.csrf import CSRFProtect
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from auth import roles_required
from config import DevelopmentConfig
from sqlalchemy import text
from models import db, Usuario, Rol
from werkzeug.security import generate_password_hash, check_password_hash
from flask_migrate import Migrate
from extensions import mail
from flask_mail import Message
import forms
from utils.db_roles import role_connection

from dashboard import dashboard_bp
from compras.routes import compras
from proveedores.routes import proveedores
from recetas.routes import recetas_bp
from produccionDiaria import produccion_diaria as pd_bp
from ventas.routes import ventas
from efectivo.routes import efectivo
from costoUtilidad.routes import costoUtilidad
from backup.routes import backup_bp
from usuarios.routes import registrar_usuario_bp
from productos.routes import productos_bp
from pedidos import pedidos_bp
from materiasPrimas.routes import materias_primas_bp

# ── Rate limiting de login ────────────────────────────────────────────────────
_login_attempts = {}   # {key: {'count': int, 'locked_until': float}}
_LOGIN_MAX_ATTEMPTS = 5
_LOGIN_LOCK_SECONDS = 180  # 3 minutos

def _get_login_key(scope):
    return f"{request.remote_addr}:{scope}"

def _check_login_lock(key):
    """Devuelve (bloqueado, segundos_restantes)."""
    entry = _login_attempts.get(key)
    if not entry:
        return False, 0
    remaining = entry.get('locked_until', 0) - time.time()
    if remaining > 0:
        return True, int(remaining)
    return False, 0

def _register_login_fail(key):
    entry = _login_attempts.setdefault(key, {'count': 0, 'locked_until': 0.0})
    entry['count'] += 1
    if entry['count'] >= _LOGIN_MAX_ATTEMPTS:
        entry['locked_until'] = time.time() + _LOGIN_LOCK_SECONDS
        entry['count'] = 0

def _clear_login_attempts(key):
    _login_attempts.pop(key, None)


app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect(app)

from logging.handlers import RotatingFileHandler

LOG_FILENAME = 'app.log'
file_handler = RotatingFileHandler(LOG_FILENAME, maxBytes=10*1024*1024, backupCount=5, encoding='utf-8')
file_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))

logging.basicConfig(level=logging.DEBUG, handlers=[file_handler])
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.DEBUG)

login_manager = LoginManager()
login_manager.login_view = 'login'
login_manager.login_message = 'Debes iniciar sesión para acceder.'

@login_manager.user_loader
def load_user(user_id):
    return db.session.get(Usuario, int(user_id))

app.register_blueprint(dashboard_bp)
app.register_blueprint(compras)
app.register_blueprint(proveedores)
app.register_blueprint(recetas_bp)
app.register_blueprint(ventas, url_prefix='/ventas')
app.register_blueprint(efectivo)
app.register_blueprint(costoUtilidad)
app.register_blueprint(backup_bp)
app.register_blueprint(registrar_usuario_bp)
app.register_blueprint(productos_bp)
app.register_blueprint(pedidos_bp)  
app.register_blueprint(materias_primas_bp)
app.register_blueprint(pd_bp)

db.init_app(app)
login_manager.init_app(app)
mail.init_app(app)
migrate = Migrate(app, db)

def _redirect_por_rol(usuario):
    clave = usuario.rol.clave_rol if usuario.rol else ''
    destinos = {
        'admin':    'dashboard',
        'empleado': 'dashboard',
        'panadero': 'pedidos.cola_produccion',
        'cliente':  'pedidos.mis_pedidos',
    }
    endpoint = destinos.get(clave, 'dashboard')
    return redirect(url_for(endpoint))

@app.context_processor
def inject_config():
    return dict(config=app.config)


@app.context_processor
def inject_url_volver():
    if not current_user.is_authenticated or not current_user.rol:
        return dict(url_volver=url_for('login'))
    destinos = {
        'admin':    'dashboard',
        'empleado': 'dashboard',
        'panadero': 'pedidos.cola_produccion',
        'cliente':  'pedidos.mis_pedidos',
    }
    endpoint = destinos.get(current_user.rol.clave_rol, 'dashboard')
    return dict(url_volver=url_for(endpoint))

@app.route("/", methods=['GET', 'POST'])
@app.route("/login", methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))

    form = forms.LoginForm(request.form)

    if request.method == 'POST':
        key = _get_login_key('admin')
        is_locked, remaining = _check_login_lock(key)
        if is_locked:
            mins = max(1, (remaining + 59) // 60)
            flash(f'Demasiados intentos fallidos. Intenta de nuevo en {mins} minuto(s).', 'error')
            return render_template("login.html", form=form)

        if form.validate():
            if not _verificar_recaptcha(request.form.get('g-recaptcha-response', '')):
                flash('Completa el reCAPTCHA para continuar.', 'error')
                return render_template("login.html", form=form)

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

                _clear_login_attempts(key)
                login_user(usuario)
                app.logger.info('Acceso exitoso | id: %s | username: %s | rol: %s | fecha: %s', usuario.id_usuario, usuario.username, usuario.rol.clave_rol if usuario.rol else 'N/A', datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                usuario.ultimo_login = datetime.datetime.now()
                db.session.commit()

                return _redirect_por_rol(usuario)
            else:
                _register_login_fail(key)
                app.logger.warning('Intento de acceso fallido (credenciales incorrectas) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                _, remaining2 = _check_login_lock(key)
                if remaining2 > 0:
                    mins = max(1, (remaining2 + 59) // 60)
                    flash(f'Demasiados intentos fallidos. Cuenta bloqueada por {mins} minuto(s).', 'error')
                else:
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
    if request.method == 'POST':
        key = _get_login_key('cliente')
        is_locked, remaining = _check_login_lock(key)
        if is_locked:
            mins = max(1, (remaining + 59) // 60)
            flash(f'Demasiados intentos fallidos. Intenta de nuevo en {mins} minuto(s).', 'error')
            return render_template("login_cliente.html", form=form)

        if form.validate():
            if not _verificar_recaptcha(request.form.get('g-recaptcha-response', '')):
                flash('Completa el reCAPTCHA para continuar.', 'error')
                return render_template("login_cliente.html", form=form)

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
                _clear_login_attempts(key)
                login_user(usuario)
                app.logger.info('Acceso cliente exitoso | id: %s | username: %s | fecha: %s', usuario.id_usuario, usuario.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                usuario.ultimo_login = datetime.datetime.now()
                db.session.commit()
                return redirect(url_for('pedidos.mis_pedidos'))
            else:
                _register_login_fail(key)
                app.logger.warning('Intento de acceso cliente fallido (credenciales incorrectas) | username: %s | fecha: %s', form.usuario.data, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                _, remaining2 = _check_login_lock(key)
                if remaining2 > 0:
                    mins = max(1, (remaining2 + 59) // 60)
                    flash(f'Demasiados intentos fallidos. Cuenta bloqueada por {mins} minuto(s).', 'error')
                else:
                    flash('Usuario o contraseña incorrectos.', 'error')

    return render_template("login_cliente.html", form=form)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _verificar_recaptcha(token):
    import requests
    
    try:
        response = requests.post(
            'https://www.google.com/recaptcha/api/siteverify',
            data={
                'secret': app.config.get('RECAPTCHA_SECRET_KEY', ''),
                'response': token,
            },
            timeout=10
        )
        result = response.json()
        print(f"reCAPTCHA response: {result}")  
        return result.get('success', False)
        
    except requests.exceptions.SSLError as e:
        print(f"SSL Error: {e}")
        flash('Error de certificado SSL. Ejecuta: pip install --upgrade certifi', 'error')
        return False
    except Exception as e:
        print(f"Error: {e}")
        flash(f'Error de conexión: {str(e)[:100]}', 'error')
        return False

def _enviar_codigo(destinatario, codigo, asunto, html_cuerpo):
    try:
        msg_mail = Message(asunto, recipients=[destinatario])
        msg_mail.html = html_cuerpo 
        mail.send(msg_mail)
    except Exception as exc:
        app.logger.error('Error al enviar correo a %s: %s', destinatario, exc)


# ── Recuperación de contraseña (clientes) ────────────────────────────────────

@app.route("/cliente/recuperar/solicitar", methods=['POST'])
def cliente_recuperar_solicitar():
    recaptcha_token = request.form.get('g-recaptcha-response', '')
    if not recaptcha_token or not _verificar_recaptcha(recaptcha_token):
        return jsonify(ok=False, error='Completa el reCAPTCHA para continuar.')

    correo = request.form.get('correo', '').strip().lower()
    if not correo:
        return jsonify(ok=False, error='Ingresa tu correo o usuario.')

    usuario = Usuario.query.filter_by(username=correo).first()
    if not usuario or not (usuario.rol and usuario.rol.clave_rol == 'cliente'):
        # respuesta genérica para no revelar si el correo existe
        return jsonify(ok=False, error='No encontramos una cuenta con ese correo.')

    if usuario.estatus != 'activo':
        return jsonify(ok=False, error='Esta cuenta no está activa.')

    codigo = str(random.randint(100000, 999999))
    session['_pending_recovery'] = {
        'id_usuario': usuario.id_usuario,
        'codigo': codigo,
        'expiry': time.time() + 600,  # 10 minutos
    }

    html_recuperacion = generar_html_correo(
        nombre=usuario.nombre_completo,
        titulo="Recuperación de Contraseña",
        mensaje_principal="Has solicitado recuperar tu contraseña en el portal de clientes de Dulce Migaja.",
        codigo=codigo,
        mensaje_secundario="Si no solicitaste esto, puedes ignorar este mensaje de forma segura. Tu cuenta está protegida."
    )

    _enviar_codigo(
        usuario.username,
        codigo,
        'Código de recuperación – Dulce Migaja',
        html_recuperacion
    )
    app.logger.info('Codigo de recuperacion enviado | id: %s | username: %s | fecha: %s',
                    usuario.id_usuario, usuario.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return jsonify(ok=True)


@app.route("/cliente/recuperar/cambiar", methods=['POST'])
def cliente_recuperar_cambiar():
    import re as _re_route
    pending = session.get('_pending_recovery')
    if not pending:
        return jsonify(ok=False, error='Sesión expirada. Vuelve a solicitar el código.')

    if time.time() > pending.get('expiry', 0):
        session.pop('_pending_recovery', None)
        return jsonify(ok=False, error='El código expiró. Vuelve a solicitar uno nuevo.')

    codigo_ingresado = request.form.get('codigo', '').strip()
    nueva_pwd        = request.form.get('nueva_password', '')
    confirmar_pwd    = request.form.get('confirmar_password', '')

    if codigo_ingresado != pending['codigo']:
        pending['intentos'] = pending.get('intentos', 0) + 1
        if pending['intentos'] >= 5:
            session.pop('_pending_recovery', None)
            return jsonify(ok=False, error='Demasiados intentos incorrectos. El código ha expirado. Solicita uno nuevo.')
        session['_pending_recovery'] = pending
        return jsonify(ok=False, error='Código incorrecto.')

    PWD_RE = _re_route.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_]).{8,}$')
    if not PWD_RE.match(nueva_pwd):
        return jsonify(ok=False, error='La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).')

    if nueva_pwd != confirmar_pwd:
        return jsonify(ok=False, error='Las contraseñas no coinciden.')

    try:
        pwd_hash = generate_password_hash(nueva_pwd)
        db.session.execute(
            text("CALL sp_cambiar_password(:id, :pwd_hash)"),
            {'id': pending['id_usuario'], 'pwd_hash': pwd_hash}
        )
        db.session.commit()
        session.pop('_pending_recovery', None)
        app.logger.info('Contrasena recuperada | id: %s | fecha: %s',
                        pending['id_usuario'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Contraseña actualizada correctamente. Ya puedes iniciar sesión.', 'success')
        return jsonify(ok=True, redirect=url_for('login_cliente'))
    except Exception as e:
        db.session.rollback()
        app.logger.error('Error al cambiar contrasena (recuperacion) | id: %s | error: %s', pending['id_usuario'], e)
        return jsonify(ok=False, error='Error al actualizar la contraseña. Intenta de nuevo.')


# ── Registro de cliente ───────────────────────────────────────────────────────

@app.route("/cliente/registro/verificar", methods=['POST'])
def registrar_cliente_verificar():
    if current_user.is_authenticated:
        return jsonify(ok=False, error='Ya tienes sesión iniciada.')

    # Verificar reCAPTCHA
    recaptcha_token = request.form.get('g-recaptcha-response', '')
    if not recaptcha_token:
        return jsonify(ok=False, error='Por favor completa el reCAPTCHA.')
    if not _verificar_recaptcha(recaptcha_token):
        return jsonify(ok=False, error='Verificación reCAPTCHA fallida. Intenta de nuevo.')

    form = forms.RegistroClienteForm(request.form)
    if not form.validate():
        errores = {}
        for field in form:
            if field.errors:
                errores[field.name] = field.errors[0]
        first_error = next(iter(errores.values()), 'Revisa los datos del formulario.')
        return jsonify(ok=False, error=first_error, errores=errores)

    correo = form.username.data.strip().lower()
    # Verificar que el correo no exista ya
    if Usuario.query.filter_by(username=correo).first():
        return jsonify(ok=False, error='Este correo ya está registrado. Intenta iniciar sesión.')

    codigo = str(random.randint(100000, 999999))
    session['_pending_registro_cliente'] = {
        'nombre':   form.nombre.data.strip(),
        'telefono': form.telefono.data.strip(),
        'username': correo,
        'pwd_hash': generate_password_hash(form.password.data),
        'codigo':   codigo,
        'expiry':   time.time() + 600,
    }

    html_registro = generar_html_correo(
        nombre=form.nombre.data.strip(),
        titulo="Portal de Clientes",
        mensaje_principal="¡Estamos emocionados de que te unas! Para finalizar la creación de tu cuenta en Dulce Migaja, utiliza el siguiente código.",
        codigo=codigo,
        mensaje_secundario="Si no intentaste registrarte, ignora este mensaje y no compartas el código con nadie."
    )

    _enviar_codigo(
        correo,
        codigo,
        'Código de verificación – Dulce Migaja',
        html_registro
    )
    app.logger.info('Codigo de registro enviado | username: %s | fecha: %s',
                    correo, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return jsonify(ok=True)


@app.route("/cliente/registro", methods=['GET', 'POST'])
def registrar_cliente():
    if current_user.is_authenticated:
        return redirect(url_for('pedidos.mis_pedidos'))

    form = forms.RegistroClienteForm(request.form)

    if request.method == 'POST':
        pending = session.get('_pending_registro_cliente')
        if not pending:
            return jsonify(ok=False, error='Sesión expirada. Vuelve a completar el formulario.')

        if time.time() > pending.get('expiry', 0):
            session.pop('_pending_registro_cliente', None)
            return jsonify(ok=False, error='El código expiró. Vuelve a completar el formulario.')

        codigo_ingresado = request.form.get('codigo', '').strip()
        if codigo_ingresado != pending['codigo']:
            pending['intentos'] = pending.get('intentos', 0) + 1
            if pending['intentos'] >= 5:
                session.pop('_pending_registro_cliente', None)
                return jsonify(ok=False, error='Demasiados intentos incorrectos. El código ha expirado. Vuelve a completar el formulario.')
            session['_pending_registro_cliente'] = pending
            return jsonify(ok=False, error='Código incorrecto.')

        try:
            db.session.execute(
                text("CALL sp_registrar_cliente(:uuid, :nombre, :telefono, :username, :pwd_hash)"),
                {
                    'uuid':     str(uuid.uuid4()),
                    'nombre':   pending['nombre'],
                    'telefono': pending['telefono'],
                    'username': pending['username'],
                    'pwd_hash': pending['pwd_hash'],
                }
            )
            db.session.commit()
            session.pop('_pending_registro_cliente', None)
            app.logger.info('Nuevo cliente registrado | username: %s | nombre: %s | fecha: %s',
                            pending['username'], pending['nombre'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('¡Cuenta creada exitosamente! Ya puedes iniciar sesión.', 'success')
            return jsonify(ok=True, redirect=url_for('login_cliente'))
        except Exception as e:
            db.session.rollback()
            orig = getattr(e, 'orig', None)
            code = orig.args[0] if orig and hasattr(orig, 'args') and len(orig.args) >= 1 else None
            msg  = orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e)
            if code == 1062 or 'ya esta en uso' in msg or 'ya está en uso' in msg:
                app.logger.warning('Intento de registro cliente con usuario ya existente | username: %s | fecha: %s',
                                   pending['username'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                return jsonify(ok=False, error='El correo ya está en uso. Elige otro.')
            else:
                app.logger.error('Error general al registrar cliente | username: %s | error: %s | fecha: %s',
                                 pending['username'], msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                return jsonify(ok=False, error=msg)

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
@roles_required('admin')
def dashboard():
    return render_template("dashboard.html")

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

# ============================================================
# API PARA MERMAS
# ============================================================

@app.route("/api/mermas/materias", methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_mermas_materias():
    """Obtener lista de materias primas para mermas"""
    busqueda = request.args.get('busqueda', '')
    
    try:
        with role_connection() as conn:
            result = conn.execute(
                text("CALL sp_mermas_materias_primas(:busqueda)"),
                {'busqueda': busqueda}
            )

            materias = []
            for row in result:
                materias.append({
                    'id_materia': row.id_materia,
                    'nombre': row.nombre,
                    'unidad_base': row.unidad_base,
                    'stock_actual': float(row.stock_actual) if row.stock_actual else 0,
                    'stock_minimo': float(row.stock_minimo) if row.stock_minimo else 0
                })

            conn.commit()

        return jsonify({
            'success': True,
            'materias': materias
        })
    except Exception as e:
        app.logger.error('Error al consultar mermas de materias primas | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/mermas/registrar", methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_registrar_merma():
    """Registrar una nueva merma"""
    try:
        data = request.get_json()
        
        # Log para depuración
        app.logger.info(f"Recibiendo solicitud de merma: {data}")
        
        if not data:
            return jsonify({'success': False, 'error': 'Datos inválidos'}), 400
        
        id_materia = data.get('id_materia')
        cantidad = data.get('cantidad')
        causa = data.get('causa')
        descripcion = data.get('descripcion', '')
        
        # Validaciones
        if not id_materia:
            return jsonify({'success': False, 'error': 'Selecciona una materia prima'}), 400
        
        try:
            cantidad = float(cantidad)
            if cantidad <= 0:
                return jsonify({'success': False, 'error': 'La cantidad debe ser mayor a cero'}), 400
        except (TypeError, ValueError):
            return jsonify({'success': False, 'error': 'Cantidad inválida'}), 400
        
        if not causa:
            return jsonify({'success': False, 'error': 'Selecciona una causa'}), 400
        
        # Validar causa
        causas_validas = ['caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro']
        if causa not in causas_validas:
            return jsonify({'success': False, 'error': 'Causa inválida'}), 400
        
        with role_connection() as conn:
            # Obtener datos de la materia prima
            materia = conn.execute(
                text("SELECT nombre, unidad_base, stock_actual FROM materias_primas WHERE id_materia = :id_materia AND estatus = 'activo'"),
                {'id_materia': id_materia}
            ).fetchone()

            if not materia:
                return jsonify({'success': False, 'error': 'Materia prima no encontrada o inactiva'}), 400

            # Validar stock suficiente
            stock_actual = float(materia.stock_actual)
            if stock_actual < cantidad:
                return jsonify({
                    'success': False,
                    'error': f'Stock insuficiente. Disponible: {stock_actual} {materia.unidad_base}'
                }), 400

            # Insertar registro de merma
            conn.execute(
                text("""
                    INSERT INTO mermas (
                        tipo_objeto, id_referencia, cantidad, unidad,
                        causa, descripcion, registrado_por, fecha_merma, creado_en
                    ) VALUES (
                        'materia_prima', :id_materia, :cantidad, :unidad,
                        :causa, :descripcion, :registrado_por, NOW(), NOW()
                    )
                """),
                {
                    'id_materia': id_materia,
                    'cantidad': cantidad,
                    'unidad': materia.unidad_base,
                    'causa': causa,
                    'descripcion': descripcion,
                    'registrado_por': current_user.id_usuario
                }
            )

            # Descontar del inventario
            conn.execute(
                text("""
                    UPDATE materias_primas
                    SET stock_actual = stock_actual - :cantidad,
                        actualizado_en = NOW()
                    WHERE id_materia = :id_materia
                """),
                {'cantidad': cantidad, 'id_materia': id_materia}
            )

            # Registrar en logs
            conn.execute(
                text("""
                    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
                    VALUES ('ajuste_inv', 'WARNING', :usuario_id, 'mermas', 'registrar_merma',
                            :desc_log, NOW())
                """),
                {
                    'usuario_id': current_user.id_usuario,
                    'desc_log': f'Merma registrada: {materia.nombre} - Cantidad: {cantidad} {materia.unidad_base} - Causa: {causa}'
                }
            )

            conn.commit()

        app.logger.info(f'Merma registrada | usuario: {current_user.username} | materia: {id_materia} | cantidad: {cantidad}')

        return jsonify({
            'success': True,
            'message': 'Merma registrada exitosamente'
        })

    except Exception as e:
        app.logger.error(f"Error en api_registrar_merma: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route("/api/mermas/listar", methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_listar_mermas():
    """Listar mermas registradas"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    causa = request.args.get('causa')
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 20))
    
    try:
        # Consulta base - simplificada sin COUNT(*) OVER para evitar problemas
        query = """
            SELECT 
                m.id_merma,
                mp.nombre AS materia_nombre,
                m.cantidad,
                m.unidad,
                m.causa,
                m.descripcion,
                m.fecha_merma,
                u.nombre_completo AS registrado_por_nombre
            FROM mermas m
            JOIN materias_primas mp ON mp.id_materia = m.id_referencia
            JOIN usuarios u ON u.id_usuario = m.registrado_por
            WHERE m.tipo_objeto = 'materia_prima'
        """
        
        params = {}
        
        if fecha_inicio and fecha_inicio != '':
            query += " AND DATE(m.fecha_merma) >= :fecha_inicio"
            params['fecha_inicio'] = fecha_inicio
        
        if fecha_fin and fecha_fin != '':
            query += " AND DATE(m.fecha_merma) <= :fecha_fin"
            params['fecha_fin'] = fecha_fin
        
        if causa and causa != '':
            query += " AND m.causa = :causa"
            params['causa'] = causa
        
        query += " ORDER BY m.fecha_merma DESC LIMIT :limit OFFSET :offset"
        params['limit'] = limit
        params['offset'] = offset
        
        with role_connection() as conn:
            result = conn.execute(text(query), params)

            mermas = []
            for row in result:
                mermas.append({
                    'id_merma': row.id_merma,
                    'materia_nombre': row.materia_nombre,
                    'cantidad': float(row.cantidad) if row.cantidad else 0,
                    'unidad': row.unidad,
                    'causa': row.causa,
                    'descripcion': row.descripcion or '',
                    'fecha_merma': row.fecha_merma.strftime('%Y-%m-%d %H:%M:%S') if row.fecha_merma else None,
                    'registrado_por_nombre': row.registrado_por_nombre
                })

            # Consulta separada para el total
            count_query = """
                SELECT COUNT(*) as total
                FROM mermas m
                JOIN materias_primas mp ON mp.id_materia = m.id_referencia
                WHERE m.tipo_objeto = 'materia_prima'
            """
            count_params = {}

            if fecha_inicio and fecha_inicio != '':
                count_query += " AND DATE(m.fecha_merma) >= :fecha_inicio"
                count_params['fecha_inicio'] = fecha_inicio

            if fecha_fin and fecha_fin != '':
                count_query += " AND DATE(m.fecha_merma) <= :fecha_fin"
                count_params['fecha_fin'] = fecha_fin

            if causa and causa != '':
                count_query += " AND m.causa = :causa"
                count_params['causa'] = causa

            total_result = conn.execute(text(count_query), count_params)
            total_filas = total_result.fetchone().total

        return jsonify({
            'success': True,
            'mermas': mermas,
            'total': total_filas,
            'offset': offset,
            'limit': limit
        })
    except Exception as e:
        app.logger.error('Error al consultar lista de mermas | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
def generar_html_correo(nombre, titulo, mensaje_principal, codigo, mensaje_secundario):
    return f"""
    <!DOCTYPE html>
    <html lang="es">
    <body style="background-color: #fdf6ec; margin: 0; padding: 40px 20px; font-family: 'Lato', Arial, sans-serif; color: #3b2a1a;">
      <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #fdf6ec;">
        <tr>
          <td align="center">
            <!-- Tarjeta Principal -->
            <table width="100%" max-width="500" cellpadding="0" cellspacing="0" border="0" style="max-width: 500px; background-color: #ffffff; border: 1px solid #e8d5b7; border-radius: 20px; box-shadow: 0 12px 40px rgba(107, 68, 35, 0.12); margin: 0 auto;">
              <tr>
                <td align="center" style="padding: 40px 30px;">
                  
                  <!-- Logo / Header -->
                  <div style="font-size: 40px; margin-bottom: 10px;">🥐</div>
                  <h1 style="font-family: 'Playfair Display', Georgia, serif; color: #6b4423; font-size: 26px; margin: 0 0 5px 0; font-weight: 700; line-height: 1.1;">Dulce Migaja</h1>
                  <div style="font-size: 11px; letter-spacing: 2px; text-transform: uppercase; color: #c8a97e; margin-bottom: 30px;">{titulo}</div>

                  <!-- Mensaje -->
                  <h2 style="font-family: 'Playfair Display', Georgia, serif; color: #6b4423; font-size: 22px; margin: 0 0 15px 0;">¡Hola, {nombre}!</h2>
                  <p style="font-size: 15px; line-height: 1.7; color: #7a5c3a; margin: 0 0 25px 0;">{mensaje_principal}</p>

                  <!-- Caja del Código -->
                  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f5ead8; border: 1px dashed #9c6f3e; border-radius: 12px; margin-bottom: 25px;">
                    <tr>
                      <td align="center" style="padding: 20px;">
                        <p style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #9c6f3e; margin: 0 0 10px 0; font-weight: 700;">Tu código de verificación</p>
                        <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #c0522a; margin: 0;">{codigo}</div>
                      </td>
                    </tr>
                  </table>

                  <p style="font-size: 14px; color: #9c7a55; margin: 0 0 30px 0;">Este código es válido por <strong>10 minutos</strong>.</p>

                  <!-- Footer -->
                  <div style="border-top: 1px solid #e8d5b7; padding-top: 20px; font-size: 12px; color: #c8a97e; line-height: 1.5;">
                    <p style="margin: 0;">{mensaje_secundario}</p>
                  </div>

                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
    
@app.route("/api/mermas/estadisticas", methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_estadisticas_mermas():
    """Obtener estadísticas de mermas"""
    try:
        with role_connection() as conn:
            # Total hoy
            result_hoy = conn.execute(
                text("SELECT COALESCE(SUM(cantidad), 0) AS total FROM mermas WHERE tipo_objeto = 'materia_prima' AND DATE(fecha_merma) = CURDATE()")
            )
            total_hoy = result_hoy.fetchone().total

            # Total semana
            result_semana = conn.execute(
                text("SELECT COALESCE(SUM(cantidad), 0) AS total FROM mermas WHERE tipo_objeto = 'materia_prima' AND YEARWEEK(fecha_merma, 1) = YEARWEEK(CURDATE(), 1)")
            )
            total_semana = result_semana.fetchone().total

        return jsonify({
            'success': True,
            'total_hoy': float(total_hoy) if total_hoy else 0,
            'total_semana': float(total_semana) if total_semana else 0
        })
    except Exception as e:
        app.logger.error('Error al consultar estadisticas de mermas | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    

# ============================================================
# API PARA MERMAS DE PRODUCTOS TERMINADOS
# ============================================================

@app.route("/api/mermas/productos", methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_mermas_productos():
    """Obtener lista de productos terminados para mermas"""
    busqueda = request.args.get('busqueda', '')
    
    try:
        with role_connection() as conn:
            result = conn.execute(
                text("CALL sp_mermas_productos_terminados(:busqueda)"),
                {'busqueda': busqueda}
            )

            productos = []
            for row in result:
                productos.append({
                    'id_producto': row.id_producto,
                    'nombre': row.nombre,
                    'precio_venta': float(row.precio_venta) if row.precio_venta else 0,
                    'stock_actual': float(row.stock_actual) if row.stock_actual else 0,
                    'stock_minimo': float(row.stock_minimo) if row.stock_minimo else 0,
                    'imagen_url': row.imagen_url
                })

            conn.commit()

        return jsonify({
            'success': True,
            'productos': productos
        })
    except Exception as e:
        app.logger.error('Error al consultar mermas de productos | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/mermas/registrar-producto", methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_registrar_merma_producto():
    """Registrar una merma de producto terminado"""
    try:
        data = request.get_json()
        
        app.logger.info(f"Recibiendo solicitud de merma de producto: {data}")
        
        if not data:
            return jsonify({'success': False, 'error': 'Datos inválidos'}), 400
        
        id_producto = data.get('id_producto')
        cantidad = data.get('cantidad')
        causa = data.get('causa')
        descripcion = data.get('descripcion', '')
        
        # Validaciones
        if not id_producto:
            return jsonify({'success': False, 'error': 'Selecciona un producto'}), 400
        
        try:
            cantidad = float(cantidad)
            if cantidad <= 0:
                return jsonify({'success': False, 'error': 'La cantidad debe ser mayor a cero'}), 400
        except (TypeError, ValueError):
            return jsonify({'success': False, 'error': 'Cantidad inválida'}), 400
        
        if not causa:
            return jsonify({'success': False, 'error': 'Selecciona una causa'}), 400
        
        # Validar causa
        causas_validas = ['caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro']
        if causa not in causas_validas:
            return jsonify({'success': False, 'error': 'Causa inválida'}), 400
        
        with role_connection() as conn:
            # Obtener datos del producto
            producto = conn.execute(
                text("""
                    SELECT p.nombre, COALESCE(i.stock_actual, 0) AS stock_actual
                    FROM productos p
                    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
                    WHERE p.id_producto = :id_producto AND p.estatus = 'activo'
                """),
                {'id_producto': id_producto}
            ).fetchone()

            if not producto:
                return jsonify({'success': False, 'error': 'Producto no encontrado o inactivo'}), 400

            # Validar stock suficiente
            stock_actual = float(producto.stock_actual)
            if stock_actual < cantidad:
                return jsonify({
                    'success': False,
                    'error': f'Stock insuficiente. Disponible: {stock_actual} piezas'
                }), 400

            # Insertar registro de merma
            conn.execute(
                text("""
                    INSERT INTO mermas (
                        tipo_objeto, id_referencia, cantidad, unidad,
                        causa, descripcion, registrado_por, fecha_merma, creado_en
                    ) VALUES (
                        'producto_terminado', :id_producto, :cantidad, 'piezas',
                        :causa, :descripcion, :registrado_por, NOW(), NOW()
                    )
                """),
                {
                    'id_producto': id_producto,
                    'cantidad': cantidad,
                    'causa': causa,
                    'descripcion': descripcion,
                    'registrado_por': current_user.id_usuario
                }
            )

            # Descontar del inventario de productos terminados
            conn.execute(
                text("""
                    UPDATE inventario_pt
                    SET stock_actual = stock_actual - :cantidad,
                        ultima_actualizacion = NOW()
                    WHERE id_producto = :id_producto
                """),
                {'cantidad': cantidad, 'id_producto': id_producto}
            )

            # Registrar en logs
            conn.execute(
                text("""
                    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
                    VALUES ('ajuste_inv', 'WARNING', :usuario_id, 'mermas', 'registrar_merma_producto',
                            :desc_log, NOW())
                """),
                {
                    'usuario_id': current_user.id_usuario,
                    'desc_log': f'Merma de producto registrada: {producto.nombre} - Cantidad: {cantidad} piezas - Causa: {causa}'
                }
            )

            conn.commit()

        app.logger.info(f'Merma de producto registrada | usuario: {current_user.username} | producto: {id_producto} | cantidad: {cantidad}')

        return jsonify({
            'success': True,
            'message': 'Merma de producto registrada exitosamente'
        })

    except Exception as e:
        app.logger.error(f"Error en api_registrar_merma_producto: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/mermas/listar-productos", methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_listar_mermas_productos():
    """Listar mermas de productos terminados"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    causa = request.args.get('causa')
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 20))
    
    try:
        query = """
            SELECT 
                m.id_merma,
                p.nombre AS producto_nombre,
                m.cantidad,
                m.unidad,
                m.causa,
                m.descripcion,
                m.fecha_merma,
                u.nombre_completo AS registrado_por_nombre
            FROM mermas m
            JOIN productos p ON p.id_producto = m.id_referencia
            JOIN usuarios u ON u.id_usuario = m.registrado_por
            WHERE m.tipo_objeto = 'producto_terminado'
        """
        
        params = {}
        
        if fecha_inicio and fecha_inicio != '':
            query += " AND DATE(m.fecha_merma) >= :fecha_inicio"
            params['fecha_inicio'] = fecha_inicio
        
        if fecha_fin and fecha_fin != '':
            query += " AND DATE(m.fecha_merma) <= :fecha_fin"
            params['fecha_fin'] = fecha_fin
        
        if causa and causa != '':
            query += " AND m.causa = :causa"
            params['causa'] = causa
        
        query += " ORDER BY m.fecha_merma DESC LIMIT :limit OFFSET :offset"
        params['limit'] = limit
        params['offset'] = offset
        
        with role_connection() as conn:
            result = conn.execute(text(query), params)

            mermas = []
            for row in result:
                mermas.append({
                    'id_merma': row.id_merma,
                    'producto_nombre': row.producto_nombre,
                    'cantidad': float(row.cantidad) if row.cantidad else 0,
                    'unidad': row.unidad,
                    'causa': row.causa,
                    'descripcion': row.descripcion or '',
                    'fecha_merma': row.fecha_merma.strftime('%Y-%m-%d %H:%M:%S') if row.fecha_merma else None,
                    'registrado_por_nombre': row.registrado_por_nombre
                })

            # Consulta para el total
            count_query = """
                SELECT COUNT(*) as total
                FROM mermas m
                JOIN productos p ON p.id_producto = m.id_referencia
                WHERE m.tipo_objeto = 'producto_terminado'
            """
            count_params = {}

            if fecha_inicio and fecha_inicio != '':
                count_query += " AND DATE(m.fecha_merma) >= :fecha_inicio"
                count_params['fecha_inicio'] = fecha_inicio

            if fecha_fin and fecha_fin != '':
                count_query += " AND DATE(m.fecha_merma) <= :fecha_fin"
                count_params['fecha_fin'] = fecha_fin

            if causa and causa != '':
                count_query += " AND m.causa = :causa"
                count_params['causa'] = causa

            total_result = conn.execute(text(count_query), count_params)
            total_filas = total_result.fetchone().total

        return jsonify({
            'success': True,
            'mermas': mermas,
            'total': total_filas,
            'offset': offset,
            'limit': limit
        })
    except Exception as e:
        app.logger.error('Error al listar mermas de productos terminados | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
     
if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.logger.info('Aplicacion iniciada correctamente')
    app.run(debug=True)
