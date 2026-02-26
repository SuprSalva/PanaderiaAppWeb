from flask import Flask, render_template, request, redirect, url_for, flash
from flask_wtf.csrf import CSRFProtect
from config import DevelopmentConfig
from models import db, Usuarios
from werkzeug.security import generate_password_hash
import forms

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
csrf = CSRFProtect()

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

@app.route("/", methods=['GET', 'POST'])
def entrar():
    form = forms.LoginForm(request.form)
    if request.method == 'POST' and form.validate():
        return redirect(url_for('dashboard'))
    return render_template("login.html", form=form)

@app.route("/login", methods=['GET', 'POST'])
def login():
    form = forms.LoginForm(request.form)
    if request.method == 'POST' and form.validate():
        return redirect(url_for('dashboard'))
    return render_template("login.html", form=form)

@app.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

@app.route("/usuarios/registrar", methods=['GET', 'POST'])
def registrar_usuario():
    form = forms.RegistroUsuarioForm(request.form)
    
    if request.method == 'POST' and form.validate():
        hashed_password = generate_password_hash(form.password.data)
        
        nuevo_usuario = Usuarios(
            nombre=form.nombre.data,
            usuario=form.usuario.data,
            password=hashed_password,
            rol=form.rol.data,
            estatus=1 
        )
        
        try:
            db.session.add(nuevo_usuario)
            db.session.commit()
            flash("Usuario registrado exitosamente")
            return redirect(url_for('dashboard'))
        except Exception as e:
            db.session.rollback()
            flash("Error: El nombre de usuario ya existe")
            
    return render_template("usuarios/registrar.html", form=form)

if __name__ == '__main__':
    csrf.init_app(app)
    db.init_app(app)
    with app.app_context():
        db.create_all() 
    app.run()