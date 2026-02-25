from wtforms import Form
from wtforms import StringField, PasswordField
from wtforms import EmailField
from wtforms import validators

class LoginForm(Form):
    usuario = StringField('Usuario', [validators.DataRequired(message="El usuario es requerido")])
    password = PasswordField('Contraseña', [validators.DataRequired()])

class RegistroUsuarioForm(Form):
    nombre = StringField('Nombre Completo', [validators.DataRequired()])
    usuario = StringField('Nombre de Usuario', [validators.Length(min=4, max=25)])
    email = EmailField('Correo Electrónico', [validators.Email()])
    password = PasswordField('Contraseña', [
        validators.DataRequired(),
        validators.Length(min=8)
    ])