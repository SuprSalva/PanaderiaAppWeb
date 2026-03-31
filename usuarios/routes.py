# usuarios/routes.py
import uuid
import re

from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user
from werkzeug.security import generate_password_hash
from sqlalchemy import text

_PWD_RE = re.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')

from models import db, Usuario, Rol
from auth import roles_required
from utils.db_roles import call_sp
from . import registrar_usuario_bp


@registrar_usuario_bp.route("/usuarios")
@login_required
@roles_required('admin')
def usuarios():
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
    nombre    = request.form.get('nombre',    '').strip()
    username  = request.form.get('username',  '').strip()
    id_rol    = request.form.get('id_rol',    '')
    password  = request.form.get('password',  '')
    confirmar = request.form.get('confirmar', '')
    estatus   = request.form.get('estatus',   'activo')

    if not nombre or not username or not id_rol or not password:
        flash('Todos los campos son obligatorios.', 'error')
        return redirect(url_for('registrar_usuario.usuarios'))

    if not _PWD_RE.match(password):
        flash('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).', 'error')
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

    if password:
        if not _PWD_RE.match(password):
            flash('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).', 'error')
            return redirect(url_for('registrar_usuario.usuarios'))
        if password != confirmar:
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


@registrar_usuario_bp.route("/cambiar-password", methods=['GET', 'POST'])
@login_required
def cambiar_password():
    if request.method == 'POST':
        actual    = request.form.get('password_actual', '')
        nueva     = request.form.get('password_nueva', '')
        confirmar = request.form.get('confirmar', '')

        usuario = db.session.get(Usuario, current_user.id_usuario)

        from werkzeug.security import check_password_hash
        if not check_password_hash(usuario.password_hash, actual):
            flash('La contraseña actual es incorrecta.', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        if not _PWD_RE.match(nueva):
            flash('La nueva contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        if nueva != confirmar:
            flash('Las contraseñas no coinciden.', 'error')
            return redirect(url_for('registrar_usuario.cambiar_password'))

        try:
            call_sp(
                "CALL sp_cambiar_password(:id, :pwd_hash)",
                {'id': current_user.id_usuario, 'pwd_hash': generate_password_hash(nueva)}
            )
            flash('Contraseña actualizada correctamente.', 'success')
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            flash(f'Error al cambiar la contraseña: {msg}', 'error')
        return redirect(url_for('registrar_usuario.cambiar_password'))

    return render_template("usuarios/cambiar_password.html")


@registrar_usuario_bp.route("/mi-perfil", methods=['GET', 'POST'])
@login_required
def mi_perfil():
    usuario = db.session.get(Usuario, current_user.id_usuario)

    if request.method == 'POST':
        nombre   = request.form.get('nombre', '').strip()
        username = request.form.get('username', '').strip()
        telefono = request.form.get('telefono', '').strip()

        if not nombre or not username:
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
            flash('Perfil actualizado correctamente.', 'success')
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            if 'ya esta en uso' in msg:
                flash(f'El usuario "{username}" ya está en uso. Elige otro.', 'error')
            else:
                flash('Error al actualizar el perfil. Intenta de nuevo.', 'error')
        return redirect(url_for('registrar_usuario.mi_perfil'))

    return render_template("usuarios/mi_perfil.html", usuario=usuario)


@registrar_usuario_bp.route("/mis-pedido")
def mis_pedidos():
    return render_template("usuarios/mispedidos.html")
