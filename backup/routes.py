"""
Módulo de Respaldo y Restauración — solo admin.
Rutas:
  GET  /backup/               → lista de respaldos + botón crear
  POST /backup/crear          → ejecuta mysqldump
  GET  /backup/descargar/<f>  → descarga un archivo .sql.gz
  POST /backup/restaurar/<f>  → restaura desde archivo guardado
  POST /backup/subir          → sube y restaura un .sql / .sql.gz
  POST /backup/eliminar/<f>   → elimina un respaldo
"""

import os
import re
import gzip
import shutil
import subprocess
import datetime

from flask import (
    Blueprint, render_template, redirect, url_for,
    flash, send_file, request, current_app
)
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from auth import roles_required
from models import db

backup_bp = Blueprint('backup', __name__, url_prefix='/backup')

# ── Configuración ────────────────────────────────────────────────────────────
DB_NAME   = 'dulce_migaja'
DB_HOST   = '127.0.0.1'
DB_PORT   = '3306'
BKP_USER  = 'dm_backup'
BKP_PASS  = 'Bkp!DulceMigaja2024#'
RST_USER  = 'dm_restore'
RST_PASS  = 'Rst!DulceMigaja2024#'

BACKUP_DIR   = r'C:\backups'
MAX_UPLOAD   = 200 * 1024 * 1024   # 200 MB
ALLOWED_EXT  = {'.sql', '.gz'}

# mysqldump puede estar en distintos lugares según el sistema
_MYSQLDUMP_CANDIDATES = [
    'mysqldump',
    r'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe',
    r'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqldump.exe',
    r'C:\xampp\mysql\bin\mysqldump.exe',
    '/usr/bin/mysqldump',
    '/usr/local/bin/mysqldump',
]
_MYSQL_CANDIDATES = [
    'mysql',
    r'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe',
    r'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe',
    r'C:\xampp\mysql\bin\mysql.exe',
    '/usr/bin/mysql',
    '/usr/local/bin/mysql',
]


def _find_bin(candidates):
    """Devuelve la primera ruta válida de la lista de candidatos."""
    for c in candidates:
        if shutil.which(c) or os.path.isfile(c):
            return c
    return candidates[0]   # fallback — dejará que subprocess falle con mensaje claro


def _backup_path(filename):
    return os.path.join(BACKUP_DIR, filename)


def _list_backups():
    """Lista archivos .sql y .sql.gz del directorio de respaldos, ordenados por fecha desc."""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    archivos = []
    for f in os.listdir(BACKUP_DIR):
        if not (f.endswith('.sql') or f.endswith('.sql.gz')):
            continue
        ruta = _backup_path(f)
        stat = os.stat(ruta)
        archivos.append({
            'nombre':  f,
            'tamaño':  stat.st_size,
            'fecha':   datetime.datetime.fromtimestamp(stat.st_mtime),
            'comprimido': f.endswith('.gz'),
        })
    archivos.sort(key=lambda x: x['fecha'], reverse=True)
    return archivos


def _tamaño_legible(bytes_):
    for unidad in ('B', 'KB', 'MB', 'GB'):
        if bytes_ < 1024:
            return f'{bytes_:.1f} {unidad}'
        bytes_ /= 1024
    return f'{bytes_:.1f} TB'


# ── Listado ──────────────────────────────────────────────────────────────────

@backup_bp.route('/')
@login_required
@roles_required('admin')
def index():
    current_app.logger.info('Vista de respaldos accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    backups = _list_backups()
    for b in backups:
        b['tamaño_fmt'] = _tamaño_legible(b['tamaño'])
    return render_template('backup/backup.html', backups=backups)


# ── Crear respaldo ────────────────────────────────────────────────────────────

@backup_bp.route('/crear', methods=['POST'])
@login_required
@roles_required('admin')
def crear():
    os.makedirs(BACKUP_DIR, exist_ok=True)
    ts       = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    nombre   = f'respaldo_{ts}.sql.gz'
    ruta_out = _backup_path(nombre)

    mysqldump = _find_bin(_MYSQLDUMP_CANDIDATES)

    cmd = [
        mysqldump,
        f'--host={DB_HOST}',
        f'--port={DB_PORT}',
        f'--user={BKP_USER}',
        f'--password={BKP_PASS}',
        '--single-transaction',
        '--routines',
        '--triggers',
        '--no-tablespaces',
        '--column-statistics=0',
        DB_NAME,
    ]

    try:
        resultado = subprocess.run(
            cmd,
            capture_output=True,
            timeout=300,
        )
        if resultado.returncode != 0:
            stderr = resultado.stderr.decode('utf-8', errors='replace')
            # Filtrar advertencia de contraseña en línea de comandos (no es error real)
            lineas_error = [l for l in stderr.splitlines()
                            if 'password' not in l.lower() and l.strip()]
            if lineas_error:
                current_app.logger.error('Error al crear respaldo | usuario: %s | error: %s | fecha: %s', current_user.username, " | ".join(lineas_error[:3]), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash(f'Error al crear el respaldo: {" | ".join(lineas_error[:3])}', 'error')
                return redirect(url_for('backup.index'))

        # Comprimir con gzip
        with gzip.open(ruta_out, 'wb') as gz:
            gz.write(resultado.stdout)

        tamaño = _tamaño_legible(os.path.getsize(ruta_out))
        current_app.logger.info('Respaldo de base de datos generado | usuario: %s | nombre: %s | tamano: %s | fecha: %s', current_user.username, nombre, tamaño, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Respaldo creado exitosamente: {nombre} ({tamaño})', 'success')

    except FileNotFoundError as e:
        current_app.logger.error('Error general de respaldo (mysqldump no encontrado) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('No se encontró mysqldump en el sistema. Verifica que MySQL esté instalado.', 'error')
    except subprocess.TimeoutExpired as e:
        current_app.logger.error('Error general de respaldo (timeout expirado) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('El respaldo tardó demasiado tiempo y fue cancelado.', 'error')
    except Exception as e:
        current_app.logger.error('Error general de respaldo | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error inesperado: {e}', 'error')

    return redirect(url_for('backup.index'))


# ── Descargar respaldo ───────────────────────────────────────────────────────

@backup_bp.route('/descargar/<nombre>')
@login_required
@roles_required('admin')
def descargar(nombre):
    nombre = secure_filename(nombre)
    ruta   = _backup_path(nombre)
    if not os.path.isfile(ruta):
        current_app.logger.warning('Intento de descargar respaldo fallido (no existe) | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Archivo no encontrado.', 'error')
        return redirect(url_for('backup.index'))
    current_app.logger.info('Descargando archivo de respaldo | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return send_file(ruta, as_attachment=True, download_name=nombre)


# ── Restaurar desde archivo guardado ─────────────────────────────────────────

@backup_bp.route('/restaurar/<nombre>', methods=['POST'])
@login_required
@roles_required('admin')
def restaurar(nombre):
    current_app.logger.info('Iniciando proceso de restauracion de base de datos desde listado | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    nombre = secure_filename(nombre)
    ruta   = _backup_path(nombre)
    if not os.path.isfile(ruta):
        current_app.logger.warning('Restauracion fallida (no existe) | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Archivo no encontrado.', 'error')
        return redirect(url_for('backup.index'))

    _ejecutar_restauracion(ruta, nombre.endswith('.gz'))
    return redirect(url_for('backup.index'))


# ── Subir y restaurar ─────────────────────────────────────────────────────────

@backup_bp.route('/subir', methods=['POST'])
@login_required
@roles_required('admin')
def subir():
    current_app.logger.info('Iniciando proceso de restauracion de base de datos via archivo externo | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    archivo = request.files.get('archivo')
    if not archivo or archivo.filename == '':
        current_app.logger.warning('Subida de restauracion fallida (archivo no recibido) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('No se seleccionó ningún archivo.', 'error')
        return redirect(url_for('backup.index'))

    nombre_seguro = secure_filename(archivo.filename)
    ext = os.path.splitext(nombre_seguro)[-1].lower()
    if ext == '.gz':
        # también aceptar .sql.gz
        pass
    elif ext != '.sql':
        current_app.logger.warning('Subida de restauracion fallida (formato invalido) | usuario: %s | archivo: %s | extension: %s | fecha: %s', current_user.username, nombre_seguro, ext, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Solo se aceptan archivos .sql o .sql.gz', 'error')
        return redirect(url_for('backup.index'))

    # Verificar tamaño antes de guardar
    archivo.seek(0, 2)
    tamaño = archivo.tell()
    archivo.seek(0)
    if tamaño > MAX_UPLOAD:
        current_app.logger.warning('Subida de restauracion fallida (limite de tamaño excedido) | usuario: %s | archivo: %s | size: %s | fecha: %s', current_user.username, nombre_seguro, tamaño, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'El archivo supera el límite de {_tamaño_legible(MAX_UPLOAD)}.', 'error')
        return redirect(url_for('backup.index'))

    os.makedirs(BACKUP_DIR, exist_ok=True)
    ruta_tmp = _backup_path('_upload_' + nombre_seguro)
    archivo.save(ruta_tmp)

    _ejecutar_restauracion(ruta_tmp, nombre_seguro.endswith('.gz'))

    # Eliminar el temporal después de restaurar
    try:
        os.remove(ruta_tmp)
    except OSError:
        pass

    return redirect(url_for('backup.index'))


# ── Eliminar respaldo ─────────────────────────────────────────────────────────

@backup_bp.route('/eliminar/<nombre>', methods=['POST'])
@login_required
@roles_required('admin')
def eliminar(nombre):
    nombre = secure_filename(nombre)
    ruta   = _backup_path(nombre)
    if os.path.isfile(ruta):
        os.remove(ruta)
        current_app.logger.info('Archivo de respaldo eliminado | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Respaldo "{nombre}" eliminado.', 'success')
    else:
        current_app.logger.warning('Intento de eliminar respaldo fallido (archivo no encontado) | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Archivo no encontrado.', 'error')
    return redirect(url_for('backup.index'))


# ── Lógica de restauración ────────────────────────────────────────────────────

_RE_DEFINER = re.compile(
    r'DEFINER\s*=\s*`[^`]*`\s*@\s*`[^`]*`\s*',
    re.IGNORECASE,
)

def _strip_definers(sql_bytes):
    """
    Elimina las cláusulas DEFINER=`user`@`host` del SQL.
    Necesario cuando el usuario de restauración no tiene SUPER
    y el dump fue creado con un definer distinto.
    """
    texto = sql_bytes.decode('utf-8', errors='replace')
    texto = _RE_DEFINER.sub('', texto)
    return texto.encode('utf-8')


def _ejecutar_restauracion(ruta_archivo, comprimido):
    mysql_bin = _find_bin(_MYSQL_CANDIDATES)

    # dm_restore tiene ALL PRIVILEGES en dulce_migaja (DROP, CREATE, ALTER, etc.)
    # Los DEFINER ya se eliminan del SQL, así no requiere SUPER.
    cmd = [
        mysql_bin,
        f'--host={DB_HOST}',
        f'--port={DB_PORT}',
        f'--user={RST_USER}',
        f'--password={RST_PASS}',
        '--default-character-set=utf8mb4',
        DB_NAME,
    ]

    try:
        if comprimido:
            with gzip.open(ruta_archivo, 'rb') as gz:
                datos_sql = gz.read()
        else:
            with open(ruta_archivo, 'rb') as f:
                datos_sql = f.read()

        # Eliminar DEFINER para evitar errores de permisos con vistas/SPs/triggers
        datos_sql = _strip_definers(datos_sql)

        # Habilitar la creación de SPs/triggers con binary logging activo.
        # Se restaura al valor 0 al terminar para no dejar el servidor inseguro.
        preambulo = b'SET GLOBAL log_bin_trust_function_creators = 1;\n'
        epilogo   = b'\nSET GLOBAL log_bin_trust_function_creators = 0;\n'
        datos_sql = preambulo + datos_sql + epilogo

        # ── Cerrar todas las conexiones activas de SQLAlchemy ─────────────────
        # Si no se hace esto, MySQL puede rechazar el DROP TABLE porque Flask
        # tiene transacciones abiertas sobre las mismas tablas.
        try:
            db.session.remove()
            db.engine.dispose()
        except Exception:
            pass

        resultado = subprocess.run(
            cmd,
            input=datos_sql,
            capture_output=True,
            timeout=600,
        )

        stderr = resultado.stderr.decode('utf-8', errors='replace')
        lineas_error = [
            l for l in stderr.splitlines()
            if l.strip() and 'password' not in l.lower()
        ]

        if resultado.returncode != 0 and lineas_error:
            current_app.logger.error('Error al restaurar base de datos | usuario: %s | error: %s | fecha: %s', current_user.username, " | ".join(lineas_error[:3]), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Error al restaurar: {" | ".join(lineas_error[:3])}', 'error')
            return

        # ── Reabrir el pool de conexiones ──────────────────────────────────────
        # dispose() lo cerró; la primera consulta siguiente lo recreará sola,
        # pero llamamos connect() para verificar que la BD quedó operativa.
        try:
            with db.engine.connect() as conn:
                conn.execute(db.text('SELECT 1'))
        except Exception:
            pass

        nombre = os.path.basename(ruta_archivo)
        current_app.logger.info('Restauracion completada con exito | usuario: %s | archivo: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Base de datos restaurada exitosamente desde "{nombre}".', 'success')

    except FileNotFoundError as e:
        current_app.logger.error('Error general de restauracion (mysql runtime no detectado) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('No se encontró el cliente mysql en el sistema. '
              'Verifica que MySQL esté instalado y en el PATH.', 'error')
    except gzip.BadGzipFile as e:
        current_app.logger.error('Error general de restauracion (gz corrupto) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('El archivo .gz está corrupto o no es un gzip válido.', 'error')
    except subprocess.TimeoutExpired as e:
        current_app.logger.error('Error general de restauracion (timeout expirado) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('La restauración tardó demasiado tiempo y fue cancelada.', 'error')
    except Exception as e:
        current_app.logger.error('Error general de restauracion | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error inesperado durante la restauración: {e}', 'error')
