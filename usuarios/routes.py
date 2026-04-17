# usuarios/routes.py
import uuid
import re
import random
import time

import datetime
from flask import render_template, request, redirect, url_for, flash, current_app, session, jsonify
from flask_login import login_required, current_user
from werkzeug.security import generate_password_hash
from flask_mail import Message
from sqlalchemy import text
from extensions import mail

_PWD_RE = re.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')

from models import db, Usuario, Rol
from auth import roles_required
from utils.db_roles import call_sp, role_connection
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


@registrar_usuario_bp.route("/usuarios/verificar-email", methods=['POST'])
@login_required
@roles_required('admin')
def verificar_email_usuario():
    """Valida el formulario, genera un código y lo envía al correo del nuevo usuario."""
    form = _usuario_form(CrearUsuarioForm)
    if not form.validate():
        first_err = next(iter(next(iter(form.errors.values()))))
        return jsonify({'ok': False, 'error': first_err}), 400

    nombre   = form.nombre.data.strip()
    username = form.username.data.strip()
    id_rol   = form.id_rol.data
    password = form.password.data
    estatus  = form.estatus.data

    codigo = str(random.randint(100000, 999999))

    session['_pending_usuario'] = {
        'nombre':   nombre,
        'username': username,
        'id_rol':   id_rol,
        'pwd_hash': generate_password_hash(password),
        'estatus':  estatus,
        'codigo':   codigo,
        'expiry':   time.time() + 600,  # 10 minutos
    }

    try:
        msg = Message(
            subject='Tu código de verificación — Dulce Migaja',
            recipients=[username],
            html=generar_html_correo(
                nombre=nombre,
                titulo="Portal de Usuarios",
                mensaje_principal="El administrador está creando una cuenta para ti en el sistema de Dulce Migaja.",
                codigo=codigo,
                mensaje_secundario="Si no solicitaste esto, puedes ignorar este mensaje de forma segura."
            )
        )
        mail.send(msg)
        current_app.logger.info(
            'Codigo de verificacion enviado | destino: %s | creador: %s | fecha: %s',
            username, current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
    except Exception as e:
        session.pop('_pending_usuario', None)
        current_app.logger.error('Error al enviar correo de verificacion | error: %s', str(e))
        return jsonify({'ok': False, 'error': 'No se pudo enviar el correo. Verifica la dirección o la configuración de correo.'}), 500

    return jsonify({'ok': True})


@registrar_usuario_bp.route("/usuarios/crear", methods=['POST'])
@login_required
@roles_required('admin')
def crear_usuario():
    """Verifica el código y crea el usuario si es correcto."""
    codigo_ingresado = request.form.get('codigo', '').strip()
    pending = session.get('_pending_usuario')

    if not pending:
        return jsonify({'ok': False, 'error': 'La sesión de verificación expiró. Cierra este modal y vuelve a llenar el formulario.'})

    if time.time() > pending['expiry']:
        session.pop('_pending_usuario', None)
        return jsonify({'ok': False, 'error': 'El código expiró (10 min). Cierra este modal y vuelve a registrar el usuario.'})

    if codigo_ingresado != pending['codigo']:
        pending['intentos'] = pending.get('intentos', 0) + 1
        current_app.logger.warning(
            'Codigo de verificacion incorrecto | creador: %s | correo: %s | intento: %s | fecha: %s',
            current_user.username, pending.get('username','?'), pending['intentos'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        if pending['intentos'] >= 5:
            session.pop('_pending_usuario', None)
            return jsonify({'ok': False, 'error': 'Demasiados intentos incorrectos. El código ha expirado. Cierra el modal y vuelve a registrar el usuario.'})
        session['_pending_usuario'] = pending
        return jsonify({'ok': False, 'error': 'Código incorrecto. Revisa el correo e inténtalo de nuevo.'})

    nombre   = pending['nombre']
    username = pending['username']
    id_rol   = pending['id_rol']
    pwd_hash = pending['pwd_hash']
    estatus  = pending['estatus']
    session.pop('_pending_usuario', None)

    try:
        with role_connection() as conn:
            conn.execute(
                text("CALL sp_crear_usuario(:uuid, :nombre, :username, :pwd_hash, :id_rol, :estatus, :creado_por)"),
                {
                    'uuid':       str(uuid.uuid4()),
                    'nombre':     nombre,
                    'username':   username,
                    'pwd_hash':   pwd_hash,
                    'id_rol':     id_rol,
                    'estatus':    estatus,
                    'creado_por': current_user.id_usuario,
                }
            )
            conn.commit()
        current_app.logger.info(
            'Usuario creado exitosamente | creador: %s | nuevo_usuario: %s | id_rol: %s | fecha: %s',
            current_user.username, username, id_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash(f'Usuario "{nombre}" creado exitosamente.', 'success')
        return jsonify({'ok': True})
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg  = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            current_app.logger.warning(
                'Creacion de usuario fallida (ya en uso) | creador: %s | username_pedido: %s | fecha: %s',
                current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': f'El correo "{username}" ya está en uso. Elige otro.'})
        elif 'no es valido' in msg or 'no es válido' in msg:
            current_app.logger.warning(
                'Creacion de usuario fallida (rol invalido) | creador: %s | rol_pedido: %s | fecha: %s',
                current_user.username, id_rol, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': 'El rol seleccionado no es válido.'})
        else:
            current_app.logger.error(
                'Error general al crear usuario | creador: %s | error: %s | fecha: %s',
                current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': 'Error al crear el usuario. Intenta de nuevo.'})


@registrar_usuario_bp.route("/usuarios/verificar-email-editar/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def verificar_email_editar(id_usuario):
    """Valida el form de edición, genera código y lo envía al nuevo correo."""
    form = _usuario_form(EditarUsuarioForm)
    if not form.validate():
        first_err = next(iter(next(iter(form.errors.values()))))
        return jsonify({'ok': False, 'error': first_err}), 400

    nombre   = form.nombre.data.strip()
    username = form.username.data.strip()
    id_rol   = form.id_rol.data
    estatus  = form.estatus.data
    password = form.password.data
    pwd_hash = generate_password_hash(password) if password else None

    codigo = str(random.randint(100000, 999999))

    session['_pending_editar_usuario'] = {
        'id_usuario': id_usuario,
        'nombre':     nombre,
        'username':   username,
        'id_rol':     id_rol,
        'estatus':    estatus,
        'pwd_hash':   pwd_hash,
        'codigo':     codigo,
        'expiry':     time.time() + 600,
    }

    try:
        msg = Message(
            subject='Verificación de cambio de correo — Dulce Migaja',
            recipients=[username],
            html=generar_html_correo(
                nombre=nombre,
                titulo="Actualización de Datos",
                mensaje_principal="El administrador está actualizando tu correo electrónico en el sistema de Dulce Migaja.",
                codigo=codigo,
                mensaje_secundario="Si no solicitaste este cambio, contacta al administrador de inmediato."
            )
        )
        mail.send(msg)
        current_app.logger.info(
            'Codigo de verificacion (editar) enviado | destino: %s | editor: %s | fecha: %s',
            username, current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
    except Exception as e:
        session.pop('_pending_editar_usuario', None)
        current_app.logger.error('Error al enviar correo de verificacion (editar) | error: %s', str(e))
        return jsonify({'ok': False, 'error': 'No se pudo enviar el correo de verificación.'}), 500

    return jsonify({'ok': True})


@registrar_usuario_bp.route("/usuarios/editar/<int:id_usuario>", methods=['POST'])
@login_required
@roles_required('admin')
def editar_usuario(id_usuario):
    pending = session.get('_pending_editar_usuario')

    if pending and pending.get('id_usuario') == id_usuario:
        # --- Flujo con verificación de correo ---
        codigo_ingresado = request.form.get('codigo', '').strip()

        if time.time() > pending['expiry']:
            session.pop('_pending_editar_usuario', None)
            return jsonify({'ok': False, 'error': 'El código expiró (10 min). Cierra el modal y vuelve a editar.'})

        if codigo_ingresado != pending['codigo']:
            pending['intentos'] = pending.get('intentos', 0) + 1
            current_app.logger.warning(
                'Codigo de verificacion (editar) incorrecto | editor: %s | correo: %s | intento: %s | fecha: %s',
                current_user.username, pending.get('username', '?'), pending['intentos'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            if pending['intentos'] >= 5:
                session.pop('_pending_editar_usuario', None)
                return jsonify({'ok': False, 'error': 'Demasiados intentos incorrectos. El código ha expirado. Cierra el modal y vuelve a editar el usuario.'})
            session['_pending_editar_usuario'] = pending
            return jsonify({'ok': False, 'error': 'Código incorrecto. Revisa el correo e inténtalo de nuevo.'})

        nombre   = pending['nombre']
        username = pending['username']
        id_rol   = pending['id_rol']
        estatus  = pending['estatus']
        pwd_hash = pending['pwd_hash']
        session.pop('_pending_editar_usuario', None)
    else:
        # --- Flujo directo (correo sin cambios) ---
        form = _usuario_form(EditarUsuarioForm)
        if not form.validate():
            first_err = next(iter(next(iter(form.errors.values()))))
            current_app.logger.warning(
                'Edicion fallida (validacion) | editor: %s | error: %s | fecha: %s',
                current_user.username, first_err, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': first_err})

        nombre   = form.nombre.data.strip()
        username = form.username.data.strip()
        id_rol   = form.id_rol.data
        estatus  = form.estatus.data
        password = form.password.data
        pwd_hash = generate_password_hash(password) if password else None

    try:
        with role_connection() as conn:
            conn.execute(
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
            conn.commit()
        current_app.logger.info(
            'Usuario actualizado | editor: %s | id: %s | username: %s | fecha: %s',
            current_user.username, id_usuario, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash(f'Usuario "{nombre}" actualizado correctamente.', 'success')
        return jsonify({'ok': True})
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg  = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        if 'ya esta en uso' in msg or 'ya está en uso' in msg:
            current_app.logger.warning(
                'Edicion fallida (ya en uso) | editor: %s | username: %s | fecha: %s',
                current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': f'El correo "{username}" ya está en uso. Elige otro.'})
        elif 'no existe' in msg:
            return jsonify({'ok': False, 'error': 'El usuario no existe.'})
        elif 'no es valido' in msg or 'no es válido' in msg:
            return jsonify({'ok': False, 'error': 'El rol seleccionado no es válido.'})
        else:
            current_app.logger.error(
                'Error general al editar usuario | editor: %s | error: %s | fecha: %s',
                current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            return jsonify({'ok': False, 'error': 'Error al actualizar el usuario. Intenta de nuevo.'})


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
        with role_connection() as conn:
            conn.execute(
                text("CALL sp_cambiar_estatus_usuario(:id, :estatus, :ejecutado_por)"),
                {
                    'id':            id_usuario,
                    'estatus':       nuevo_estatus,
                    'ejecutado_por': current_user.id_usuario,
                }
            )
            conn.commit()
        accion = 'activado' if nuevo_estatus == 'activo' else 'desactivado'
        current_app.logger.info('Estatus de usuario cambiado | ejecutor: %s | id_afectado: %s | nuevo_estatus: %s | fecha: %s', current_user.username, id_usuario, nuevo_estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Usuario {accion} correctamente.', 'success')
    except Exception as e:
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


@registrar_usuario_bp.route("/cambiar-password/verificar", methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def verificar_cambio_password():
    """Valida las contraseñas, genera código y lo envía al correo del usuario."""
    actual    = request.form.get('password_actual', '')
    nueva     = request.form.get('password_nueva', '')
    confirmar = request.form.get('confirmar', '')

    usuario = db.session.get(Usuario, current_user.id_usuario)

    from werkzeug.security import check_password_hash
    if not check_password_hash(usuario.password_hash, actual):
        current_app.logger.warning('Cambio de contrasena fallido (actual incorrecta) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': False, 'error': 'La contraseña actual es incorrecta.'})

    if not _PWD_RE.match(nueva):
        current_app.logger.warning('Cambio de contrasena fallido (requisitos no cumplidos) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': False, 'error': 'La nueva contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).'})

    if nueva != confirmar:
        current_app.logger.warning('Cambio de contrasena fallido (no coinciden) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': False, 'error': 'Las contraseñas no coinciden.'})

    codigo = str(random.randint(100000, 999999))
    session['_pending_pwd'] = {
        'pwd_hash': generate_password_hash(nueva),
        'codigo':   codigo,
        'expiry':   time.time() + 600,
    }

    try:
        msg = Message(
            subject='Código de verificación — Cambio de contraseña',
            recipients=[current_user.username],
            html=generar_html_correo(
                nombre=current_user.nombre_completo, # Asumiendo que existe este campo, si no, usa current_user.nombre
                titulo="Seguridad de la Cuenta",
                mensaje_principal="Se ha solicitado un cambio de contraseña para tu cuenta de Dulce Migaja.",
                codigo=codigo,
                mensaje_secundario="Si no solicitaste este cambio, por favor contacta al administrador de inmediato para proteger tu cuenta."
            )
        )
        mail.send(msg)
        current_app.logger.info('Codigo de verificacion (pwd) enviado | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    except Exception as e:
        session.pop('_pending_pwd', None)
        current_app.logger.error('Error al enviar correo de verificacion (pwd) | error: %s', str(e))
        return jsonify({'ok': False, 'error': 'No se pudo enviar el correo de verificación. Intenta de nuevo.'})

    return jsonify({'ok': True, 'correo': current_user.username})


@registrar_usuario_bp.route("/cambiar-password", methods=['GET', 'POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def cambiar_password():
    if request.method == 'POST':
        codigo_ingresado = request.form.get('codigo', '').strip()
        pending = session.get('_pending_pwd')

        if not pending:
            return jsonify({'ok': False, 'error': 'La sesión expiró. Vuelve a iniciar el proceso.'})

        if time.time() > pending['expiry']:
            session.pop('_pending_pwd', None)
            return jsonify({'ok': False, 'error': 'El código expiró (10 min). Vuelve a iniciar el proceso.'})

        if codigo_ingresado != pending['codigo']:
            pending['intentos'] = pending.get('intentos', 0) + 1
            current_app.logger.warning('Codigo de verificacion (pwd) incorrecto | usuario: %s | intento: %s | fecha: %s', current_user.username, pending['intentos'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            if pending['intentos'] >= 5:
                session.pop('_pending_pwd', None)
                return jsonify({'ok': False, 'error': 'Demasiados intentos incorrectos. El código ha expirado. Vuelve a iniciar el proceso.'})
            session['_pending_pwd'] = pending
            return jsonify({'ok': False, 'error': 'Código incorrecto. Revisa tu correo e inténtalo de nuevo.'})

        pwd_hash = pending['pwd_hash']
        session.pop('_pending_pwd', None)

        try:
            call_sp(
                "CALL sp_cambiar_password(:id, :pwd_hash)",
                {'id': current_user.id_usuario, 'pwd_hash': pwd_hash}
            )
            current_app.logger.info('Contrasena actualizada correctamente | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash('Contraseña actualizada correctamente.', 'success')
            return jsonify({'ok': True})
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            current_app.logger.error('Error general al cambiar contrasena | usuario: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            return jsonify({'ok': False, 'error': f'Error al cambiar la contraseña: {msg}'})

    return render_template("usuarios/cambiar_password.html")


@registrar_usuario_bp.route("/mi-perfil/verificar-email", methods=['POST'])
@login_required
@roles_required('cliente')
def mi_perfil_verificar_email():
    """Valida el nuevo correo, genera código y lo envía."""
    nombre   = request.form.get('nombre', '').strip()
    username = request.form.get('username', '').strip().lower()
    telefono = request.form.get('telefono', '').strip()

    if not nombre or not username:
        return jsonify({'ok': False, 'error': 'Nombre y correo son obligatorios.'})

    import re as _re_email
    if not _re_email.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', username):
        return jsonify({'ok': False, 'error': 'Introduce un correo electrónico válido.'})

    pending = session.get('_pending_perfil')
    if pending and pending.get('username') == username and time.time() < pending.get('expiry', 0):
        return jsonify({'ok': True, 'correo': username, 'message': 'Ya se envió un código. Revisa tu correo.'})

    codigo = str(random.randint(100000, 999999))
    session['_pending_perfil'] = {
        'nombre':   nombre,
        'username': username,
        'telefono': telefono or None,
        'codigo':   codigo,
        'expiry':   time.time() + 600,
    }

    try:
        msg = Message(
            subject='Verificación de correo — Mi Perfil · Dulce Migaja',
            recipients=[username],
            html=generar_html_correo(
                nombre=nombre,
                titulo="Gestión de Perfil",
                mensaje_principal="Has solicitado un cambio de correo electrónico en tu cuenta de Dulce Migaja.",
                codigo=codigo,
                mensaje_secundario="Si no fuiste tú quien solicitó esto, ignora este mensaje y revisa la seguridad de tu cuenta."
            )
        )
        mail.send(msg)
        current_app.logger.info(
            'Codigo de verificacion (perfil) enviado | destino: %s | usuario: %s | fecha: %s',
            username, current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
    except Exception as e:
        session.pop('_pending_perfil', None)
        current_app.logger.error('Error al enviar correo verificacion perfil | error: %s', str(e))
        return jsonify({'ok': False, 'error': 'No se pudo enviar el correo de verificación. Intenta de nuevo.'})

    return jsonify({'ok': True, 'correo': username})


@registrar_usuario_bp.route("/mi-perfil", methods=['GET', 'POST'])
@login_required
@roles_required('cliente')
def mi_perfil():
    usuario = db.session.get(Usuario, current_user.id_usuario)

    if request.method == 'POST':
        pending = session.get('_pending_perfil')

        if pending:
            # --- Flujo con verificación de correo ---
            codigo_ingresado = request.form.get('codigo', '').strip()

            if time.time() > pending['expiry']:
                session.pop('_pending_perfil', None)
                return jsonify({'ok': False, 'error': 'El código expiró (10 min). Vuelve a intentarlo.'})

            if codigo_ingresado != pending['codigo']:
                pending['intentos'] = pending.get('intentos', 0) + 1
                current_app.logger.warning(
                    'Codigo perfil incorrecto | usuario: %s | intento: %s | fecha: %s',
                    current_user.username, pending['intentos'], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                )
                if pending['intentos'] >= 5:
                    session.pop('_pending_perfil', None)
                    return jsonify({'ok': False, 'error': 'Demasiados intentos incorrectos. El código ha expirado. Vuelve a intentarlo.'})
                session['_pending_perfil'] = pending
                return jsonify({'ok': False, 'error': 'Código incorrecto. Revisa tu correo e inténtalo de nuevo.'})

            nombre   = pending['nombre']
            username = pending['username']
            telefono = pending['telefono']
            session.pop('_pending_perfil', None)
        else:
            # --- Flujo directo (sin cambio de correo) ---
            nombre   = request.form.get('nombre', '').strip()
            username = request.form.get('username', '').strip()
            telefono = request.form.get('telefono', '').strip()

            if not nombre or not username:
                return jsonify({'ok': False, 'error': 'Nombre y correo son obligatorios.'})

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
            current_app.logger.info(
                'Perfil actualizado | usuario: %s | fecha: %s',
                current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash('Perfil actualizado correctamente.', 'success')
            return jsonify({'ok': True})
        except Exception as e:
            msg = str(e.orig) if hasattr(e, 'orig') else str(e)
            if 'ya esta en uso' in msg:
                current_app.logger.warning(
                    'Perfil fallido (email en uso) | usuario: %s | pedido: %s | fecha: %s',
                    current_user.username, username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                )
                return jsonify({'ok': False, 'error': f'El correo "{username}" ya está en uso.'})
            else:
                current_app.logger.error(
                    'Error al actualizar perfil | usuario: %s | error: %s | fecha: %s',
                    current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                )
                return jsonify({'ok': False, 'error': 'Error al actualizar el perfil. Intenta de nuevo.'})

    return render_template("usuarios/mi_perfil.html", usuario=usuario)


@registrar_usuario_bp.route("/mis-pedido")
@login_required
@roles_required('cliente')
def mis_pedidos():
    current_app.logger.info('Acceso a listado de pedidos de cliente | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return render_template("usuarios/mispedidos.html")

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