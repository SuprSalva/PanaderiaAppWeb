import re as _re

from wtforms import (
    Form, StringField, PasswordField, SelectField,
    TextAreaField, DecimalField, IntegerField, HiddenField,
    FieldList, FormField, validators, BooleanField
)
from wtforms.validators import Optional, NumberRange, DataRequired, ValidationError, Length

_USR_PWD_RE = _re.compile(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_]).{8,}$')


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
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).')

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
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).')

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
            raise ValidationError('La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).')

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

class ItemVentaForm(Form):
    """Formulario para cada producto en una venta"""
    id_producto = HiddenField('ID Producto', [DataRequired(message='Producto requerido')])
    nombre = HiddenField('Nombre')
    cantidad = DecimalField('Cantidad', 
                           [DataRequired(message='Cantidad requerida'),
                            NumberRange(min=0.01, message='La cantidad debe ser mayor a 0')],
                           places=2)
    precio_unitario = DecimalField('Precio Unitario',
                                   [DataRequired(message='Precio requerido'),
                                    NumberRange(min=0, message='El precio no puede ser negativo')],
                                   places=2)
    descuento_pct = DecimalField('Descuento %',
                                 [NumberRange(min=0, max=100, message='El descuento debe estar entre 0 y 100')],
                                 places=2, default=0)


class VentaForm(Form):
    """Formulario principal para registrar una venta"""
    metodo_pago = SelectField('Método de Pago',
                             choices=[
                                 ('efectivo', '💵 Efectivo'),
                                 ('tarjeta', '💳 Tarjeta'),
                                 ('transferencia', '🔁 Transferencia'),
                                 ('otro', '📦 Otro')
                             ],
                             validators=[DataRequired(message='Selecciona un método de pago')])
    
    monto_recibido = DecimalField('Monto Recibido (Efectivo)',
                                  [NumberRange(min=0, message='El monto no puede ser negativo')],
                                  places=2, default=0)
    
    requiere_ticket = BooleanField('Imprimir Ticket', default=True)
    
    observaciones = TextAreaField('Observaciones',
                                  [Length(max=500, message='Máximo 500 caracteres')])
    
    items = FieldList(FormField(ItemVentaForm), min_entries=1, 
                      validators=[DataRequired(message='Agrega al menos un producto')])


class FiltroVentasForm(Form):
    """Formulario para filtrar el listado de ventas"""
    fecha_inicio = StringField('Fecha Inicio', [Optional()])
    fecha_fin = StringField('Fecha Fin', [Optional()])
    metodo_pago = SelectField('Método de Pago',
                             choices=[
                                 ('', 'Todos'),
                                 ('efectivo', 'Efectivo'),
                                 ('tarjeta', 'Tarjeta'),
                                 ('transferencia', 'Transferencia'),
                                 ('otro', 'Otro')
                             ],
                             validators=[Optional()])
    
    estado = SelectField('Estado',
                        choices=[
                            ('', 'Todos'),
                            ('completada', 'Completada'),
                            ('cancelada', 'Cancelada'),
                            ('abierta', 'Abierta')
                        ],
                        validators=[Optional()])
    
    vendedor_id = SelectField('Vendedor', coerce=int, validators=[Optional()])
    
    def __init__(self, *args, **kwargs):
        super(FiltroVentasForm, self).__init__(*args, **kwargs)
        # Las opciones de vendedor se cargarán dinámicamente desde la base de datos


class CancelarVentaForm(Form):
    """Formulario para cancelar una venta"""
    motivo_cancelacion = TextAreaField('Motivo de Cancelación',
                                       [Length(max=500, message='Máximo 500 caracteres')])
    
    confirmar = BooleanField('Confirmar cancelación',
                            validators=[DataRequired(message='Debes confirmar la cancelación')])


class CorteVentaForm(Form):
    """Formulario para realizar corte de ventas"""
    fecha_corte = StringField('Fecha de Corte',
                              [DataRequired(message='La fecha es obligatoria')])
    
    efectivo_sistema = DecimalField('Efectivo según sistema',
                                    [DataRequired(message='Campo requerido')],
                                    places=2)
    
    efectivo_contado = DecimalField('Efectivo contado',
                                    [DataRequired(message='Campo requerido')],
                                    places=2)
    
    tarjeta_sistema = DecimalField('Tarjeta según sistema',
                                   [DataRequired(message='Campo requerido')],
                                   places=2)
    
    tarjeta_contado = DecimalField('Tarjeta contado',
                                   [DataRequired(message='Campo requerido')],
                                   places=2)
    
    transferencia_sistema = DecimalField('Transferencia según sistema',
                                         [DataRequired(message='Campo requerido')],
                                         places=2)
    
    transferencia_contado = DecimalField('Transferencia contado',
                                         [DataRequired(message='Campo requerido')],
                                         places=2)
    
    observaciones = TextAreaField('Observaciones del corte',
                                  [Length(max=500, message='Máximo 500 caracteres')])
    
    def validate_efectivo_contado(self, field):
        if self.efectivo_sistema.data and field.data:
            diferencia = abs(field.data - self.efectivo_sistema.data)
            if diferencia > 5:  # Tolerancia de $5
                raise ValidationError(f'Diferencia de ${diferencia:.2f} en efectivo. Verifica el conteo.')
    
    def validate_tarjeta_contado(self, field):
        if self.tarjeta_sistema.data and field.data:
            diferencia = abs(field.data - self.tarjeta_sistema.data)
            if diferencia > 5:
                raise ValidationError(f'Diferencia de ${diferencia:.2f} en tarjeta. Verifica el conteo.')
    
    def validate_transferencia_contado(self, field):
        if self.transferencia_sistema.data and field.data:
            diferencia = abs(field.data - self.transferencia_sistema.data)
            if diferencia > 5:
                raise ValidationError(f'Diferencia de ${diferencia:.2f} en transferencias. Verifica el conteo.')


class BusquedaProductoVentaForm(Form):
    """Formulario para buscar productos en el POS"""
    busqueda = StringField('Buscar producto',
                          [Length(max=100, message='Máximo 100 caracteres')])
    
    categoria = SelectField('Categoría',
                           choices=[
                               ('', 'Todas'),
                               ('pan_dulce', 'Pan Dulce'),
                               ('pan_salado', 'Pan Salado'),
                               ('reposteria', 'Repostería'),
                               ('especial', 'Especialidades')
                           ],
                           validators=[Optional()])


class TicketForm(Form):
    """Formulario para reimprimir ticket"""
    folio_venta = StringField('Folio de Venta',
                             [DataRequired(message='El folio es obligatorio'),
                              Length(min=5, max=20, message='Folio inválido')])
    
    tipo_ticket = SelectField('Tipo de Ticket',
                             choices=[
                                 ('original', 'Original'),
                                 ('copia', 'Copia'),
                                 ('factura', 'Factura (CFDI)')
                             ],
                             default='original')


class DevolucionForm(Form):
    """Formulario para devolución de productos"""
    folio_venta_original = StringField('Folio de Venta Original',
                                       [DataRequired(message='El folio original es obligatorio')])
    
    productos = FieldList(FormField(ItemVentaForm), min_entries=1,
                         validators=[DataRequired(message='Selecciona al menos un producto a devolver')])
    
    motivo_devolucion = SelectField('Motivo de Devolución',
                                   choices=[
                                       ('producto_defectuoso', 'Producto defectuoso'),
                                       ('cliente_arrepentimiento', 'Cliente se arrepintió'),
                                       ('error_venta', 'Error en la venta'),
                                       ('otro', 'Otro')
                                   ],
                                   validators=[DataRequired(message='Selecciona un motivo')])
    
    observaciones = TextAreaField('Observaciones',
                                  [Length(max=500, message='Máximo 500 caracteres')])
    
    metodo_reembolso = SelectField('Método de Reembolso',
                                  choices=[
                                      ('mismo_metodo', 'Mismo método de pago'),
                                      ('efectivo', 'Efectivo'),
                                      ('credito_tienda', 'Crédito en tienda')
                                  ],
                                  validators=[DataRequired(message='Selecciona método de reembolso')])