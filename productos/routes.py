import io
import os
import uuid as _uuid
import datetime

from flask import (
    render_template, request, redirect, url_for,
    flash, jsonify, current_app,
)
from flask_login import login_required, current_user
from PIL import Image
from werkzeug.datastructures import CombinedMultiDict
from werkzeug.utils import secure_filename

from auth import roles_required
from models import db, Producto, InventarioPT
from forms import ProductoForm
from . import productos_bp

_CARPETA_IMG = os.path.join('uploads', 'productos')

def _ruta_static():
    ruta = os.path.join(current_app.static_folder, _CARPETA_IMG)
    os.makedirs(ruta, exist_ok=True)
    return ruta


def _guardar_imagen(file_storage) -> str | None:
    if not file_storage or not getattr(file_storage, 'filename', ''):
        return None
    file_storage.stream.seek(0)
    contenido = file_storage.stream.read()
    img = Image.open(io.BytesIO(contenido))
    if img.mode not in ('RGB', 'RGBA'):
        img = img.convert('RGB')
    nombre_archivo = f'{_uuid.uuid4().hex}.webp'
    ruta_disco     = os.path.join(_ruta_static(), nombre_archivo)
    img.save(ruta_disco, format='WEBP', quality=85, method=4)
    return os.path.join(_CARPETA_IMG, nombre_archivo).replace('\\', '/')


def _eliminar_imagen_fisica(imagen_url: str | None):
    if not imagen_url:
        return
    try:
        ruta = os.path.join(current_app.static_folder, imagen_url)
        if os.path.isfile(ruta):
            os.remove(ruta)
    except Exception as exc:
        current_app.logger.warning('No se pudo eliminar imagen física: %s | %s', imagen_url, exc)


def _sp_actualizar_imagen(id_producto: int, imagen_url: str | None):
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_actualizar_imagen_producto(%s, %s)", (id_producto, imagen_url))
    cur.close()
    db.session.commit()


def _form_con_archivos():
    if request.files:
        return CombinedMultiDict([request.files, request.form])
    return request.form


@productos_bp.route('/productos', methods=['GET'])
@login_required
@roles_required('admin', 'empleado')
def index_productos():
    current_app.logger.info(
        'Vista de inventario de productos accesada | usuario: %s | fecha: %s',
        current_user.username,
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    )

    lista           = Producto.query.order_by(Producto.nombre).all()
    total           = len(lista)
    total_activos   = sum(1 for p in lista if p.estatus == 'activo')
    total_inactivos = total - total_activos

    form_nueva = ProductoForm()

    return render_template(
        'productos/productos.html',
        productos=lista,
        total=total,
        total_activos=total_activos,
        total_inactivos=total_inactivos,
        form_nueva=form_nueva,
    )

@productos_bp.route('/productos/nuevo', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def productos_nuevo():
    form = ProductoForm(_form_con_archivos())

    if not form.validate():
        current_app.logger.warning(
            'Creacion de producto fallida (validacion) | usuario: %s | fecha: %s',
            current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('productos_bp.index_productos', modal='nuevo'))

    imagen_url = None
    try:
        imagen_url = _guardar_imagen(form.imagen.data)
    except Exception as exc:
        current_app.logger.error('Error al guardar imagen | %s', exc)
        flash('Error al procesar la imagen. El producto se creará sin imagen.', 'warning')

    nuevo = Producto(
        uuid_producto  = str(_uuid.uuid4()),
        nombre         = form.nombre.data.strip(),
        descripcion    = (form.descripcion.data or '').strip() or None,
        precio_venta   = float(form.precio_venta.data),
        imagen_url     = imagen_url,
        estatus        = 'activo',
        creado_en      = datetime.datetime.now(),
        actualizado_en = datetime.datetime.now(),
        creado_por     = None,
    )
    db.session.add(nuevo)
    db.session.flush()

    inv = InventarioPT(id_producto=nuevo.id_producto, stock_actual=0, stock_minimo=0)
    try:
        db.session.add(inv)
        db.session.commit()
        current_app.logger.info(
            'Producto creado | usuario: %s | producto: %s | fecha: %s',
            current_user.username, nuevo.nombre,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        flash(f'Producto "{nuevo.nombre}" creado correctamente.', 'success')
    except Exception as exc:
        db.session.rollback()
        _eliminar_imagen_fisica(imagen_url)
        current_app.logger.error('Error al crear producto | %s', exc)
        flash('Error al guardar el producto. Intenta de nuevo.', 'error')

    return redirect(url_for('productos_bp.index_productos'))


@productos_bp.route('/productos/<int:id_producto>/editar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def productos_editar(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    form     = ProductoForm(_form_con_archivos())

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('productos_bp.index_productos'))

    nueva_imagen = None
    imagen_vieja = producto.imagen_url

    archivo = form.imagen.data
    if archivo and getattr(archivo, 'filename', ''):
        try:
            nueva_imagen = _guardar_imagen(archivo)
        except Exception as exc:
            current_app.logger.error('Error al procesar imagen en edición | %s', exc)
            flash('Error al procesar la imagen. Se mantiene la imagen anterior.', 'warning')

    try:
        producto.nombre         = form.nombre.data.strip()
        producto.descripcion    = (form.descripcion.data or '').strip() or None
        producto.precio_venta   = float(form.precio_venta.data)
        producto.actualizado_en = datetime.datetime.now()
        if nueva_imagen:
            producto.imagen_url = nueva_imagen
        db.session.commit()
        if nueva_imagen and imagen_vieja:
            _eliminar_imagen_fisica(imagen_vieja)
        current_app.logger.info(
            'Producto editado | usuario: %s | id: %d | fecha: %s',
            current_user.username, id_producto,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        flash(f'Producto "{producto.nombre}" actualizado.', 'success')
    except Exception as exc:
        db.session.rollback()
        _eliminar_imagen_fisica(nueva_imagen)
        current_app.logger.error('Error al editar producto | %s', exc)
        flash('Error al actualizar el producto.', 'error')

    return redirect(url_for('productos_bp.index_productos'))


@productos_bp.route('/productos/<int:id_producto>/imagen', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def imagen_subir(id_producto):
    producto = Producto.query.get_or_404(id_producto)

    archivo = request.files.get('imagen')
    if not archivo or not archivo.filename:
        return jsonify({'ok': False, 'msg': 'No se recibió ningún archivo.'}), 400

    # Verificar que sea imagen válida con Pillow directamente
    try:
        archivo.stream.seek(0)
        img = Image.open(archivo.stream)
        img.verify()          # valida firma sin decodificar todo
        archivo.stream.seek(0)  # rebobinar para _guardar_imagen
    except Exception:
        return jsonify({'ok': False, 'msg': 'El archivo no tiene firma de imagen válida.'}), 400

    try:
        nueva_url    = _guardar_imagen(archivo)
        imagen_vieja = producto.imagen_url
        _sp_actualizar_imagen(id_producto, nueva_url)
        _eliminar_imagen_fisica(imagen_vieja)
        current_app.logger.info(
            'Imagen subida | usuario: %s | producto: %d | fecha: %s',
            current_user.username, id_producto,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        return jsonify({'ok': True, 'msg': 'Imagen actualizada.',
                        'url': url_for('static', filename=nueva_url)})
    except Exception as exc:
        current_app.logger.error('Error al subir imagen | %s', exc)
        return jsonify({'ok': False, 'msg': 'Error interno al procesar la imagen.'}), 500

@productos_bp.route('/productos/<int:id_producto>/imagen/quitar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def imagen_quitar(id_producto):
    producto      = Producto.query.get_or_404(id_producto)
    imagen_actual = producto.imagen_url

    if not imagen_actual:
        return jsonify({'ok': False, 'msg': 'Este producto no tiene imagen.'}), 400

    try:
        _sp_actualizar_imagen(id_producto, None)
        _eliminar_imagen_fisica(imagen_actual)
        current_app.logger.info(
            'Imagen eliminada | usuario: %s | producto: %d | fecha: %s',
            current_user.username, id_producto,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        return jsonify({'ok': True, 'msg': 'Imagen eliminada.'})
    except Exception as exc:
        current_app.logger.error('Error al quitar imagen | %s', exc)
        return jsonify({'ok': False, 'msg': 'Error interno al eliminar la imagen.'}), 500


@productos_bp.route('/productos/toggle/<int:id_producto>', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def productos_toggle(id_producto):
    producto      = Producto.query.get_or_404(id_producto)
    nuevo_estatus = 'inactivo' if producto.estatus == 'activo' else 'activo'

    try:
        producto.estatus        = nuevo_estatus
        producto.actualizado_en = datetime.datetime.now()
        db.session.commit()
        current_app.logger.info(
            'Estatus de producto cambiado | usuario: %s | id: %d | estatus: %s | fecha: %s',
            current_user.username, id_producto, nuevo_estatus,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        )
        flash(f'Producto marcado como {nuevo_estatus}.', 'success')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error('Error al cambiar estatus | %s', exc)
        flash('Error al cambiar el estatus.', 'error')

    return redirect(url_for('productos_bp.index_productos'))