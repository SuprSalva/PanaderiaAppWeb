import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Usuarios(db.Model):
    __tablename__ = 'usuarios'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    usuario = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False) 
    rol = db.Column(db.String(20))
    estatus = db.Column(db.Integer, default=1)
    ultimo_acceso = db.Column(db.DateTime)
    created_date = db.Column(db.DateTime, default=datetime.datetime.now)
    id_modificacion = db.Column(db.Integer, nullable=True)
    fecha_modificacion = db.Column(db.DateTime, onupdate=datetime.datetime.now)