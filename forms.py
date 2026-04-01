from wtforms import (
    Form, StringField, PasswordField, SelectField,
    TextAreaField, DecimalField, IntegerField, HiddenField,
    FieldList, FormField, validators
)
from wtforms.validators import Optional, NumberRange, DataRequired, ValidationError, Length


class LoginForm(Form):
    usuario  = StringField('Usuario',    [validators.DataRequired(message="El usuario es obligatorio")])
    password = PasswordField('Contraseña', [validators.DataRequired(message="La contraseña es obligatoria")])


class RegistroUsuarioForm(Form):
    nombre = StringField('Nombre Completo', [
        validators.DataRequired(message="El nombre es obligatorio"),
        validators.Length(min=3, max=120)
    ])
    usuario = StringField('Nombre de Usuario', [
        validators.DataRequired(message="El usuario es obligatorio"),
        validators.Length(min=4, max=60)
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
    stock_minimo = DecimalField('Stock Mínimo (pzas)', [
        Optional(),
        NumberRange(min=0, message='El stock mínimo no puede ser negativo.'),
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