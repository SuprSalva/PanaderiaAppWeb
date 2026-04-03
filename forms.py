import re as _re

from wtforms import (
    Form, StringField, PasswordField, SelectField,
    TextAreaField, DecimalField, IntegerField, HiddenField,
    FieldList, FormField, validators
)
from wtforms.validators import Optional, NumberRange, DataRequired, ValidationError, Length

_USR_PWD_RE = _re.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')


class LoginForm(Form):
    usuario  = StringField('Usuario',    [validators.DataRequired(message="El usuario es obligatorio")])
    password = PasswordField('Contraseña', [validators.DataRequired(message="La contraseña es obligatoria")])


class RegistroUsuarioForm(Form):
    nombre = StringField('Nombre Completo', [
        validators.DataRequired(message="El nombre es obligatorio"),
        validators.Length(min=3, max=120, message="El nombre debe tener entre 3 y 120 caracteres.")
    ])
    usuario = StringField('Nombre de Usuario', [
        validators.DataRequired(message="El usuario es obligatorio"),
        validators.Length(min=4, max=60, message="El usuario debe tener entre 4 y 60 caracteres.")
    ])
    password = PasswordField('Contraseña', [
        validators.DataRequired(message="La contraseña es obligatoria"),
        validators.Regexp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_+\-])[A-Za-z\d@$!%*?&_+\-]{8,}$',
            message="Mín. 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial."
        )
    ])
    rol = SelectField('Rol del Sistema', choices=[
        ('admin',    'Administrador'),
        ('empleado', 'Empleado'),
        ('panadero', 'Panadero'),
    ])


class CompraForm(Form):
    """Valida el encabezado de un pedido de compra (nueva o edición)."""
    id_proveedor  = SelectField('Proveedor', coerce=int,
                                validators=[DataRequired(message='Selecciona un proveedor.')])
    fecha_compra  = StringField('Fecha de Compra',
                                [DataRequired(message='La fecha de compra es obligatoria.')])
    folio_factura = StringField('No. Factura / Referencia',
                                [Optional(), Length(max=60)])
    observaciones = StringField('Observaciones',
                                [Optional(), Length(max=500)])


class RegistroClienteForm(Form):
    """Registro público de clientes (el rol siempre es 'cliente')."""
    nombre    = StringField('Nombre Completo', [DataRequired(message='El nombre es obligatorio.'), Length(min=3, max=120, message='El nombre debe tener entre 3 y 120 caracteres.')])
    telefono  = StringField('Teléfono', [DataRequired(message='El teléfono es obligatorio.'), Length(max=20, message='El teléfono no puede exceder 20 caracteres.')])
    username  = StringField('Usuario', [DataRequired(message='El usuario es obligatorio.'), Length(min=4, max=60, message='El usuario debe tener entre 4 y 60 caracteres.')])
    password  = PasswordField('Contraseña', [DataRequired(message='La contraseña es obligatoria.')])
    confirmar = PasswordField('Confirmar Contraseña', [DataRequired(message='Confirma la contraseña.')])

    def validate_password(self, field):
        if field.data and not _USR_PWD_RE.match(field.data):
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).')

    def validate_confirmar(self, field):
        if self.password.data and field.data != self.password.data:
            raise ValidationError('Las contraseñas no coinciden.')


class CrearUsuarioForm(Form):
    """Valida el formulario de creación de usuario (password obligatorio)."""
    nombre    = StringField('Nombre Completo', [DataRequired(message='El nombre es obligatorio.'), Length(min=3, max=120, message='El nombre debe tener entre 3 y 120 caracteres.')])
    username  = StringField('Usuario', [DataRequired(message='El usuario es obligatorio.'), Length(min=4, max=60, message='El usuario debe tener entre 4 y 60 caracteres.')])
    id_rol    = SelectField('Rol', coerce=int, validators=[NumberRange(min=1, message='Selecciona un rol.')])
    password  = PasswordField('Contraseña', [DataRequired(message='La contraseña es obligatoria.')])
    confirmar = PasswordField('Confirmar Contraseña', [DataRequired(message='Confirma la contraseña.')])
    estatus   = SelectField('Estatus', choices=[('activo', 'Activo'), ('inactivo', 'Inactivo')])

    def validate_password(self, field):
        if field.data and not _USR_PWD_RE.match(field.data):
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).')

    def validate_confirmar(self, field):
        if self.password.data and field.data != self.password.data:
            raise ValidationError('Las contraseñas no coinciden.')


class EditarUsuarioForm(Form):
    """Valida el formulario de edición de usuario (password opcional)."""
    nombre    = StringField('Nombre Completo', [DataRequired(message='El nombre es obligatorio.'), Length(min=3, max=120, message='El nombre debe tener entre 3 y 120 caracteres.')])
    username  = StringField('Usuario', [DataRequired(message='El usuario es obligatorio.'), Length(min=4, max=60, message='El usuario debe tener entre 4 y 60 caracteres.')])
    id_rol    = SelectField('Rol', coerce=int, validators=[NumberRange(min=1, message='Selecciona un rol.')])
    password  = PasswordField('Contraseña', [Optional()])
    confirmar = PasswordField('Confirmar Contraseña', [Optional()])
    estatus   = SelectField('Estatus', choices=[('activo', 'Activo'), ('inactivo', 'Inactivo'), ('bloqueado', 'Bloqueado')])

    def validate_password(self, field):
        if field.data and not _USR_PWD_RE.match(field.data):
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&).')

    def validate_confirmar(self, field):
        if self.password.data and field.data != self.password.data:
            raise ValidationError('Las contraseñas no coinciden.')


class RecetaForm(Form):
    id_producto = SelectField(
        'Producto',
        coerce=int,
        validators=[validators.DataRequired(message="Selecciona un producto.")],
    )
    nombre = StringField('Nombre de la Receta', [
        validators.DataRequired(message="El nombre es obligatorio."),
        validators.Length(max=120, message="Máximo 120 caracteres."),
    ])
    descripcion = TextAreaField('Notas / Instrucciones', [
        Optional(),
        validators.Length(max=2000),
    ])
    rendimiento = DecimalField('Rendimiento', [
        validators.DataRequired(message="El rendimiento es obligatorio."),
        NumberRange(min=0.01, message="El rendimiento debe ser mayor a 0."),
    ], places=2)
    unidad_rendimiento = SelectField('Unidad de Rendimiento', choices=[
        ('pza', 'Piezas'),
    ])
    precio_venta = DecimalField('Precio de Venta / pieza ($)', [
        Optional(),
        NumberRange(min=0, message="El precio no puede ser negativo."),
    ], places=2)


class ProductoForm(Form):
    nombre = StringField('Nombre del Producto', [
        validators.DataRequired(message='El nombre es obligatorio.'),
        validators.Length(max=120, message='Máximo 120 caracteres.'),
    ])
    descripcion = TextAreaField('Descripción', [
        Optional(),
        validators.Length(max=2000),
    ])
    precio_venta = DecimalField('Precio de Venta ($)', [
        validators.DataRequired(message='El precio de venta es obligatorio.'),
        NumberRange(min=0.01, message='El precio debe ser mayor a 0.'),
    ], places=2)

class PanCajaForm(Form):

    class Meta:
        csrf = False      

    id_producto = HiddenField('Producto', validators=[DataRequired()])
    cantidad    = HiddenField('Cantidad', validators=[DataRequired()])
    precio      = HiddenField('Precio',   validators=[DataRequired()])

    def validate_id_producto(self, field):
        try:
            v = int(field.data)
            if v <= 0:
                raise ValidationError('Producto inválido.')
        except (TypeError, ValueError):
            raise ValidationError('Producto inválido.')

    def validate_cantidad(self, field):
        try:
            v = int(field.data)
            if v <= 0:
                raise ValidationError('La cantidad debe ser mayor a 0.')
        except (TypeError, ValueError):
            raise ValidationError('Cantidad inválida.')

    def validate_precio(self, field):
        try:
            v = float(field.data)
            if v < 0:
                raise ValidationError('El precio no puede ser negativo.')
        except (TypeError, ValueError):
            raise ValidationError('Precio inválido.')


class CajaForm(Form):
    class Meta:
        csrf = False

    id_tamanio = HiddenField('Tamaño', validators=[DataRequired(message='Selecciona un tamaño.')])
    tipo       = HiddenField('Tipo',   validators=[DataRequired(message='Selecciona el tipo de caja.')])
    panes      = FieldList(FormField(PanCajaForm), min_entries=1)

    def validate_id_tamanio(self, field):
        try:
            v = int(field.data)
            if v <= 0:
                raise ValidationError('Tamaño de charola inválido.')
        except (TypeError, ValueError):
            raise ValidationError('Tamaño de charola inválido.')

    def validate_tipo(self, field):
        if field.data not in ('simple', 'mixta', 'triple'):
            raise ValidationError('Tipo de caja inválido.')

    def validate_panes(self, field):
        tipo  = self.tipo.data
        n     = len([p for p in field.entries if p.id_producto.data])
        regla = {'simple': 1, 'mixta': 2, 'triple': 3}
        esperado = regla.get(tipo)
        if esperado and n != esperado:
            nombres = {1: 'un tipo', 2: 'dos tipos', 3: 'tres tipos'}
            raise ValidationError(
                f'Una caja {tipo} requiere exactamente {nombres[esperado]} de pan.'
            )


class PedidoCajaForm(Form):
    fecha_recogida = HiddenField('Fecha y hora de recolección',
                                 validators=[DataRequired(message='Indica la fecha y hora de recolección.')])
    cajas          = FieldList(FormField(CajaForm), min_entries=1)

    def validate_fecha_recogida(self, field):
        from datetime import datetime
        try:
            datetime.strptime(field.data, '%Y-%m-%d %H:%M')
        except ValueError:
            raise ValidationError('Formato de fecha inválido.')

    def validate_cajas(self, field):
        if len(field.entries) == 0:
            raise ValidationError('Agrega al menos una caja al pedido.')
        

class SalidaEfectivoForm(Form):
    """Valida el registro manual de una salida de efectivo."""
    id_proveedor = SelectField(
        'Proveedor', coerce=int,
        validators=[Optional()],
    )
    categoria = SelectField(
        'Categoría',
        choices=[
            ('compra_insumos',      '🛒 Compra de Insumos'),
            ('servicios_utilities', '⚡ Servicios / Utilities'),
            ('mantenimiento',       '🔧 Mantenimiento'),
            ('otros',               '📦 Otros'),
        ],
        validators=[DataRequired(message='Selecciona una categoría.')],
    )
    descripcion = StringField('Descripción', [
        DataRequired(message='La descripción es obligatoria.'),
        Length(max=255, message='La descripción no puede exceder 255 caracteres.'),
    ])
    monto = DecimalField('Monto', [
        DataRequired(message='El monto es obligatorio.'),
        NumberRange(min=0.01, message='El monto debe ser mayor a cero.'),
    ], places=2)
    fecha_salida = StringField('Fecha', [
        DataRequired(message='La fecha es obligatoria.'),
    ])


class ProveedorForm(Form):
    nombre = StringField('Nombre / Razón Social', [
        validators.DataRequired(message='El nombre es obligatorio.'),
        validators.Length(max=150, message='Máximo 150 caracteres.'),
    ])
    rfc = StringField('RFC', [
        Optional(),
        validators.Length(max=13, message='El RFC no puede exceder 13 caracteres.'),
        validators.Regexp(
            r'^$|^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$',
            message='RFC inválido. Formato esperado: 3-4 letras, 6 dígitos, 3 alfanuméricos.',
        ),
    ])
    contacto = StringField('Persona de Contacto', [
        Optional(),
        validators.Length(max=120, message='Máximo 120 caracteres.'),
    ])
    telefono = StringField('Teléfono', [
        Optional(),
        validators.Length(max=20, message='Máximo 20 caracteres.'),
    ])
    email = StringField('Correo Electrónico', [
        Optional(),
        validators.Regexp(
            r'^$|^[^@\s]+@[^@\s]+\.[^@\s]+$',
            message='Correo electrónico inválido.',
        ),
        validators.Length(max=150, message='Máximo 150 caracteres.'),
    ])
    direccion = TextAreaField('Dirección', [
        Optional(),
        validators.Length(max=2000, message='Máximo 2000 caracteres.'),
    ])

class CostoUtilidadFiltroForm(Form):
    """Formulario de filtros para el reporte de Costos y Utilidad."""

    buscar = StringField('Buscar Producto', [
        Optional(),
        validators.Length(max=120),
    ])

    orden = SelectField('Ordenar por', choices=[
        ('nombre_asc',  'Nombre A-Z'),
        ('margen_desc', 'Mayor Margen'),
        ('margen_asc',  'Menor Margen'),
        ('costo_desc',  'Mayor Costo'),
        ('costo_asc',   'Menor Costo'),
    ], default='nombre_asc')

    utilidad_min = DecimalField('Utilidad mínima ($)', [
        Optional(),
        NumberRange(min=0, message='Debe ser mayor o igual a 0.'),
    ], places=2)

    utilidad_max = DecimalField('Utilidad máxima ($)', [
        Optional(),
        NumberRange(min=0, message='Debe ser mayor o igual a 0.'),
    ], places=2)