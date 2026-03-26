from wtforms import Form, StringField, PasswordField, SelectField, TextAreaField, DecimalField, validators
from wtforms.validators import Optional, NumberRange


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