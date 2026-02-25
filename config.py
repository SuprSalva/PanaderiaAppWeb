import os

class Config(object):
    SECRET_KEY = "DulceMigajaSecretKey" 
    SESSION_COOKIE_SECURE = False

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://web_user:123@127.0.0.1/dulce_migaja'
    SQLALCHEMY_TRACK_MODIFICATIONS = False