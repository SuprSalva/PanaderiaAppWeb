# usuarios/routes.py
import uuid
import re

import datetime
from flask import render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required, current_user
from werkzeug.security import generate_password_hash
from sqlalchemy import text

_PWD_RE = re.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')

from models import db, Usuario, Rol
from auth import roles_required
from utils.db_roles import call_sp
from forms import CrearUsuarioForm, EditarUsuarioForm
from . import registrar_usuario_bp


def _usuario_form(FormClass):
    form = FormClass(request.form)
    form.id_rol.choices = (
        [(0, '— Seleccionar —')] +
        [(r.id_rol, r.nombre_rol) for r in Rol.query.order_by(Rol.nombre_rol).all()]
    )
    return form


@registrar_usuario_bp.route("/usuarios")
@login_required
@roles_required('admin')
def usuarios():
    current_app.logger.info('Vista de panel de usuarios accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    lista = db.session.execute(
        text("SELECT * FROM vw_usuarios ORDER BY nombre_completo")
    ).mappings().all()
    roles     = Rol.query.order_by(Rol.nombre_rol).all()
    total     = len(lista)
    activos   = sum(1 for u in lista if u.estatus == 'activo')
    inactivos = total - activos
    num_roles = Rol.query.count()
    return render_template("usuarios/usuarios.html",
        usuarios=lista,
        roles=roles,
        total=total,
        activos=activos,
        inactivos=inactivos,
        num_roles=num_roles,
    )


@registrar_usuario_bp.route("/usuarios/crear", methods=['POST'])
@login_required
@roles_required('admin')
def crear_usuario():
    form = _usuario_form(CrearUsuarioForm)
    if not form.validate():
        first_err = next(iter(next(iter(form.errors.values()))))
        current_app.logger.warning('Intento de creacion de usuario fallido (error de validacion) | creador: %s | error: %s | fecha: %s', current_user.username, first_err, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(first_err, 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    nombre   = form.nombre.data.strip()
    username = form.username.data.strip()
    id_rol   = form.id_rol.data
    password = form.password.data
    estatus  = form.estatus.data

    try:
        db.session.execute(
            text("CALL sp_crear_usuario(:uuid, :nombre, :username, :pwd_hash, :id_rol, :estatus, :creado_por)"),
            {
                'uuid':       str(uuid.uuid4()),
                'nombre':     nombre,
                'username':   username,
                'pwd_hash':   generate_password_hash(password),
                'id_rol':     id_rol,
                'estatus':    estatus,
                'creado_por': current_user.id_usuario,
            }
        )
        db.session.commit()
        current_app.logger.info('Usuario creado exitosamente | creador: %s | nuevo_usuario: %s | id_rol: %s | fecha: %s', current_user.username, username, id_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Usuario "{nombre}" creado exitosamente.', 'success')
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg  = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            current_app.logger.warning('Creacion de usuario fallida (ya en uso) | creador: %s | username_pedido: %s | fecha: %s', current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
        elif 'no es valido' in msg or 'no es válido' in msg:
            current_app.logger.warning('Creacion de usuario fallida (rol invalido) | creador: %s | rol_pedido: %s | fecha: %s', current_user.username, id_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El rol seleccionado no es válido.', 'error')
        else:
            current_app.logger.error('Error general al crear usuario | creador: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Error al crear el usuario. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/usuarios/editar/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def editar_usuario(id_usuario):
    form = _usuario_form(EditarUsuarioForm)
    if not form.validate():
        first_err = next(iter(next(iter(form.errors.values()))))
        current_app.logger.warning('Intento de edicion de usuario fallido (error de validacion) | editor: %s | error: %s | fecha: %s', current_user.username, first_err, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(first_err, 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    nombre   = form.nombre.data.strip()
    username = form.username.data.strip()
    id_rol   = form.id_rol.data
    estatus  = form.estatus.data
    password = form.password.data

    pwd_hash = generate_password_hash(password) if password else None

    try:
        db.session.execute(
            text("CALL sp_editar_usuario(:id, :nombre, :username, :id_rol, :estatus, :pwd_hash)"),
            {
                'id':       id_usuario,
                'nombre':   nombre,
                'username': username,
                'id_rol':   id_rol,
                'estatus':  estatus,
                'pwd_hash': pwd_hash,
            }
        )
        db.session.commit()
        current_app.logger.info('Usuario actualizado exitosamente | editor: %s | usuario_editado_id: %s | username: %s | fecha: %s', current_user.username, id_usuario, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Usuario "{nombre}" actualizado correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg  = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            current_app.logger.warning('Edicion de usuario fallida (username ya en uso) | editor: %s | username_pedido: %s | fecha: %s', current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
        elif 'no existe' in msg:
            current_app.logger.warning('Edicion de usuario fallida (usuario no existe) | editor: %s | id_pedido: %s | fecha: %s', current_user.username, id_usuario, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El usuario no existe.', 'error')
        elif 'no es valido' in msg or 'no es válido' in msg:
            current_app.logger.warning('Edicion de usuario fallida (rol invalido) | editor: %s | rol_pedido: %s | fecha: %s', current_user.username, id_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El rol seleccionado no es válido.', 'error')
        else:
            current_app.logger.error('Error general al editar usuario | editor: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Error al actualizar el usuario. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/usuarios/estatus/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def cambiar_estatus_usuario(id_usuario):
    nuevo_estatus = request.form.get('estatus', '')

    if nuevo_estatus not in ('activo', 'inactivo'):
        current_app.logger.warning('Cambio de estatus fallido (estatus invalido) | usuario: %s | valor_recibido: %s | fecha: %s', current_user.username, nuevo_estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Estatus no válido.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    try:
        db.session.execute(
            text("CALL sp_cambiar_estatus_usuario(:id, :estatus, :ejecutado_por)"),
            {
                'id':            id_usuario,
                'estatus':       nuevo_estatus,
                'ejecutado_por': current_user.id_usuario,
            }
        )
        db.session.commit()
        accion = 'activado' if nuevo_estatus == 'activo' else 'desactivado'
        current_app.logger.info('Estatus de usuario cambiado | ejecutor: %s | id_afectado: %s | nuevo_estatus: %s | fecha: %s', current_user.username, id_usuario, nuevo_estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Usuario {accion} correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        if 'propia cuenta' in msg:
            current_app.logger.warning('Cambio de estatus fallido (propia cuenta) | usuario: %s | id_afectado: %s | fecha: %s', current_user.username, id_usuario, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('No puedes desactivar tu propia cuenta.', 'error')
        elif 'no existe' in msg:
            current_app.logger.warning('Cambio de estatus fallido (no existe) | usuario: %s | id_afectado: %s | fecha: %s', current_user.username, id_usuario, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('El usuario no existe.', 'error')
        else:
            current_app.logger.error('Error general al cambiar estatus | usuario: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Error al cambiar el estatus. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/cambiar-password", methods=['GET', 'POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def cambiar_password():
    if request.method == 'POST':
        actual    = request.form.get('password_actual', '')
        nueva     = request.form.get('password_nueva', '')
        confirmar = request.form.get('confirmar', '')

        usuario = db.session.get(Usuario, current_user.id_usuario)

        from werkzeug.security import check_password_hash
        if not check_password_hash(usuario.password_hash, actual):
            current_app.logger.warning('Cambio de contraseña fallido (actual incorrecta) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('La contraseña actual es incorrecta.', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        if not _PWD_RE.match(nueva):
            current_app.logger.warning('Cambio de contraseña fallido (requisitos no cumplidos) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('La nueva contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        if nueva != confirmar:
            current_app.logger.warning('Cambio de contraseña fallido (no coinciden las nuevas) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Las contraseñas no coinciden.', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        try:
            call_sp(
                "CALL sp_cambiar_password(:id, :pwd_hash)",
                {'id': current_user.id_usuario, 'pwd_hash': generate_password_hash(nueva)}
            )
            current_app.logger.info('Contraseña actualizada correctamente | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Contraseña actualizada correctamente.', 'success')
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            current_app.logger.error('Error general al cambiar contraseña | usuario: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Error al cambiar la contraseña: {msg}', 'error')
        return redirect(url_for('registrar_usuario.cambiar_password'))

    return render_template("usuarios/cambiar_password.html")


@registrar_usuario_bp.route("/mi-perfil", methods=['GET', 'POST'])
@login_required
@roles_required('cliente')
def mi_perfil():
    usuario = db.session.get(Usuario, current_user.id_usuario)

    if request.method == 'POST':
        nombre   = request.form.get('nombre', '').strip()
        username = request.form.get('username', '').strip()
        telefono = request.form.get('telefono', '').strip()

        if not nombre or not username:
            current_app.logger.warning('Actualizacion de perfil fallida (campos vacios) | usuario actual: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Nombre y usuario son obligatorios.', 'error')
            return redirect(url_for('registrar_usuario.mi_perfil'))

        try:
            call_sp(
                "CALL sp_actualizar_perfil_cliente(:id, :nombre, :username, :telefono)",
                {
                    'id':       current_user.id_usuario,
                    'nombre':   nombre,
                    'username': username,
                    'telefono': telefono or None,
                }
            )
            current_app.logger.info('Perfil actualizado correctamente | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Perfil actualizado correctamente.', 'success')
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            if 'ya esta en uso' in msg:
                current_app.logger.warning('Actualizacion de perfil fallida (username en uso) | usuario: %s | pedido: %s | fecha: %s', current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
            else:
                current_app.logger.error('Error al actualizar perfil | usuario: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash('Error al actualizar el perfil. Intenta de nuevo.', 'error')
        return redirect(url_for('registrar_usuario.mi_perfil'))

    return render_template("usuarios/mi_perfil.html", usuario=usuario)


@registrar_usuario_bp.route("/mis-pedido")
@login_required
@roles_required('cliente')
def mis_pedidos():
    current_app.logger.info('Acceso a listado de pedidos de cliente | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return render_template("usuarios/mispedidos.html")
