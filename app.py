import uuid
import datetime
import logging

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_wtf.csrf import CSRFProtect
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from auth import roles_required
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
app.register_blueprint(ventas, url_prefix='/ventas')
app.register_blueprint(efectivo)
app.register_blueprint(costoUtilidad)
app.register_blueprint(registrar_usuario_bp)
app.register_blueprint(productos_bp)
app.register_blueprint(pedidos_bp)  
app.register_blueprint(materias_primas_bp)

db.init_app(app)
login_manager.init_app(app)
migrate = Migrate(app, db)

def _redirect_por_rol(usuario):
    clave = usuario.rol.clave_rol if usuario.rol else ''
    destinos = {
        'admin':    'dashboard',
        'empleado': 'dashboard_ventas',
        'panadero': 'pedidos.cola_produccion',
        'cliente':  'pedidos.mis_pedidos',
    }
    endpoint = destinos.get(clave, 'dashboard')
    return redirect(url_for(endpoint))

@app.context_processor
def inject_url_volver():
    if not current_user.is_authenticated or not current_user.rol:
        return dict(url_volver=url_for('login'))
    destinos = {
        'admin':    'dashboard',
        'empleado': 'dashboard_ventas',
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

            return _redirect_por_rol(usuario)
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
@roles_required('admin')
def dashboard():
    return render_template("dashboard.html")

@app.route("/dashboardVentas")
@login_required
@roles_required('admin', 'empleado')
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

# ============================================================
# API PARA MERMAS
# ============================================================

@app.route("/api/mermas/materias", methods=['GET'])
@login_required
def api_mermas_materias():
    """Obtener lista de materias primas para mermas"""
    busqueda = request.args.get('busqueda', '')
    
    try:
        result = db.session.execute(
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
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'materias': materias
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_mermas_materias: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/mermas/registrar", methods=['POST'])
@login_required
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
        
        # Obtener datos de la materia prima
        materia = db.session.execute(
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
        db.session.execute(
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
        db.session.execute(
            text("""
                UPDATE materias_primas 
                SET stock_actual = stock_actual - :cantidad,
                    actualizado_en = NOW()
                WHERE id_materia = :id_materia
            """),
            {'cantidad': cantidad, 'id_materia': id_materia}
        )
        
        # Registrar en logs
        db.session.execute(
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
        
        db.session.commit()
        
        app.logger.info(f'Merma registrada | usuario: {current_user.username} | materia: {id_materia} | cantidad: {cantidad}')
        
        return jsonify({
            'success': True,
            'message': 'Merma registrada exitosamente'
        })
        
    except Exception as e:
        db.session.rollback()
        app.logger.error(f"Error en api_registrar_merma: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route("/api/mermas/listar", methods=['GET'])
@login_required
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
        
        result = db.session.execute(text(query), params)
        
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
        
        total_result = db.session.execute(text(count_query), count_params)
        total_filas = total_result.fetchone().total
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'mermas': mermas,
            'total': total_filas,
            'offset': offset,
            'limit': limit
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_listar_mermas: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
@app.route("/api/mermas/estadisticas", methods=['GET'])
@login_required
def api_estadisticas_mermas():
    """Obtener estadísticas de mermas"""
    try:
        # Total hoy
        result_hoy = db.session.execute(
            text("SELECT COALESCE(SUM(cantidad), 0) AS total FROM mermas WHERE tipo_objeto = 'materia_prima' AND DATE(fecha_merma) = CURDATE()")
        )
        total_hoy = result_hoy.fetchone().total
        
        # Total semana
        result_semana = db.session.execute(
            text("SELECT COALESCE(SUM(cantidad), 0) AS total FROM mermas WHERE tipo_objeto = 'materia_prima' AND YEARWEEK(fecha_merma, 1) = YEARWEEK(CURDATE(), 1)")
        )
        total_semana = result_semana.fetchone().total
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'total_hoy': float(total_hoy) if total_hoy else 0,
            'total_semana': float(total_semana) if total_semana else 0
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_estadisticas_mermas: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
     
if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.logger.info('Aplicacion iniciada correctamente')
    app.run(debug=True)



