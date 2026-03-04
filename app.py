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
    return render_template("dashboardVentas.html")

@app.route("/usuarios")
def usuarios():
    return render_template("usuarios/usuarios.html")

@app.route("/proveedores")
def proveedores():
    return render_template("proveedores/proveedores.html")

@app.route("/materias-primas")
def materias_primas():
    return render_template("proveedores/materiasPrimas/materiasPrimas.html")

@app.route("/compras")
def compras():
    return render_template("compras/compras.html")

@app.route("/recetas")
def recetas():
    return render_template("recetas/recetas.html")

@app.route("/produccion")
def produccion():
    return render_template("produccion/produccion.html")

@app.route("/producto-terminado")
def producto_terminado():
    return render_template("productoTerminado/productoTerminado.html")

@app.route("/produccion-solicitud")
def produccion_solicitud():
    return render_template("produccion/solicitudes.html")

@app.route("/ventas")
def ventas():
    return render_template("ventas/ventas.html")

@app.route("/corte-ventas")
def corte_ventas():
    return render_template("ventas/corteVentas.html")

@app.route("/salida-efectivo")
def salida_efectivo():
    return render_template("efectivo/salidaEfectivo.html")


@app.route("/costoUtilidad")
def costo_utilidad():
    return render_template("costoUtilidad/costoUtilidad.html")

@app.route("/utilidad")
def utilidad():
    return render_template("costoUtilidad/utilidad.html")


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