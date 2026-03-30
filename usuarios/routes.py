# usuarios/routes.py
import uuid

from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user
from werkzeug.security import generate_password_hash
from sqlalchemy import text

from models import db, Usuario, Rol
from auth import roles_required
from . import registrar_usuario_bp


@registrar_usuario_bp.route("/usuarios")
@login_required
@roles_required('admin')
def usuarios():
    lista = Usuario.query.order_by(Usuario.nombre_completo).all()
    roles = Rol.query.order_by(Rol.nombre_rol).all()
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
    nombre    = request.form.get('nombre',    '').strip()
    username  = request.form.get('username',  '').strip()
    id_rol    = request.form.get('id_rol',    '')
    password  = request.form.get('password',  '')
    confirmar = request.form.get('confirmar', '')
    estatus   = request.form.get('estatus',   'activo')

    if not nombre or not username or not id_rol or not password:
        flash('Todos los campos son obligatorios.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    if password != confirmar:
        flash('Las contraseñas no coinciden.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    try:
        db.session.execute(
            text("CALL sp_crear_usuario(:uuid, :nombre, :username, :pwd_hash, :id_rol, :estatus, :creado_por)"),
            {
                'uuid':       str(uuid.uuid4()),
                'nombre':     nombre,
                'username':   username,
                'pwd_hash':   generate_password_hash(password),
                'id_rol':     int(id_rol),
                'estatus':    estatus,
                'creado_por': current_user.id_usuario,
            }
        )
        db.session.commit()
        flash(f'Usuario "{nombre}" creado exitosamente.', 'success')
    except Exception as e:
        db.session.rollback()
        msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
        elif 'no es valido' in msg or 'no es válido' in msg:
            flash('El rol seleccionado no es válido.', 'error')
        else:
            flash('Error al crear el usuario. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/usuarios/editar/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def editar_usuario(id_usuario):
    nombre    = request.form.get('nombre',    '').strip()
    username  = request.form.get('username',  '').strip()
    id_rol    = request.form.get('id_rol',    '')
    estatus   = request.form.get('estatus',   'activo')
    password  = request.form.get('password',  '').strip()
    confirmar = request.form.get('confirmar', '').strip()

    if not nombre or not username or not id_rol:
        flash('Nombre, usuario y rol son obligatorios.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    if password and password != confirmar:
        flash('Las contraseñas no coinciden.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    pwd_hash = generate_password_hash(password) if password else None

    try:
        db.session.execute(
            text("CALL sp_editar_usuario(:id, :nombre, :username, :id_rol, :estatus, :pwd_hash)"),
            {
                'id':       id_usuario,
                'nombre':   nombre,
                'username': username,
                'id_rol':   int(id_rol),
                'estatus':  estatus,
                'pwd_hash': pwd_hash,
            }
        )
        db.session.commit()
        flash(f'Usuario "{nombre}" actualizado correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
        elif 'no existe' in msg:
            flash('El usuario no existe.', 'error')
        elif 'no es valido' in msg or 'no es válido' in msg:
            flash('El rol seleccionado no es válido.', 'error')
        else:
            flash('Error al actualizar el usuario. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/usuarios/estatus/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def cambiar_estatus_usuario(id_usuario):
    nuevo_estatus = request.form.get('estatus', '')

    if nuevo_estatus not in ('activo', 'inactivo'):
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
        flash(f'Usuario {accion} correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        msg = str(e.orig) if hasattr(e, 'orig') else str(e)
        if 'propia cuenta' in msg:
            flash('No puedes desactivar tu propia cuenta.', 'error')
        elif 'no existe' in msg:
            flash('El usuario no existe.', 'error')
        else:
            flash('Error al cambiar el estatus. Intenta de nuevo.', 'error')

    return redirect(url_for('registrar_usuario.usuarios'))


@registrar_usuario_bp.route("/mis-pedido")
def mis_pedidos():
    return render_template("usuarios/mispedidos.html")
