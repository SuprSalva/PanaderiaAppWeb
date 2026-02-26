from wtforms import Form
from wtforms import StringField, PasswordField
from wtforms import EmailField
from wtforms import validators
from wtforms import SelectField
import re

class LoginForm(Form):
    usuario = StringField('Usuario', [validators.DataRequired(message="El usuario es obligatorio")])
    password = PasswordField('Contraseña', [validators.DataRequired(message="La contraseña es obligatoria")])

class RegistroUsuarioForm(Form):
    nombre = StringField('Nombre Completo', [
        validators.DataRequired(message="El nombre es obligatorio"),
        validators.Length(min=3, max=100)
    ])
    usuario = StringField('Nombre de Usuario', [
        validators.DataRequired(message="El usuario es obligatorio"),
        validators.Length(min=4, max=50)
    ])
    password = PasswordField('Contraseña', [
        validators.DataRequired(message="La contraseña es obligatoria"),
        validators.Regexp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_+\-*])[A-Za-z\d@$!%*?&_+\-*]{8,}$',
            message="La contraseña debe tener mín. 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial (@$!%*?&_+-*)."
        )
    ])
    rol = SelectField('Rol del Sistema', choices=[
        ('admin', 'Administrador'),
        ('empleado', 'Empleado'),
        ('panadero', 'Panadero')
    ])