import os
import base64
import uuid
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
# NUEVAS LIBRERÍAS DE SEGURIDAD
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash

# ================= CONFIGURACIÓN =================
app = Flask(__name__)
CORS(app)

basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'denuncias.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# SEGURIDAD: JWT CONFIG (En producción usar variables de entorno)
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'super-secreto-duoc-2024')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)

UPLOAD_DIR = os.path.join(basedir, "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

db = SQLAlchemy(app)
jwt = JWTManager(app)

# ================= MODELOS DE BASE DE DATOS =================

# NUEVO MODELO DE USUARIO
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Denuncia(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    correo = db.Column(db.String(120), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    latitud = db.Column(db.Float, nullable=True)
    longitud = db.Column(db.Float, nullable=True)
    image_filename = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        root = request.url_root.rstrip('/')
        return {
            "id": self.id,
            "correo": self.correo,
            "descripcion": self.descripcion,
            "ubicacion": {"lat": self.latitud, "lng": self.longitud},
            "image_url": f"{root}/uploads/{self.image_filename}",
            "fecha": self.created_at.strftime("%Y-%m-%d %H:%M")
        }

with app.app_context():
    db.create_all()

# ================= RUTAS DE AUTENTICACIÓN (NUEVO) =================

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if User.query.filter_by(email=email).first():
        return jsonify({"msg": "El usuario ya existe"}), 400

    new_user = User(email=email)
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"msg": "Usuario creado exitosamente"}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()

    if not user or not user.check_password(password):
        return jsonify({"msg": "Credenciales inválidas"}), 401

    # Crear Token JWT
    access_token = create_access_token(identity=email)
    return jsonify(access_token=access_token), 200

# ================= RUTAS DE DENUNCIAS =================

@app.route("/api/denuncias", methods=["GET"])
@jwt_required() # AHORA PROTEGIDO
def list_denuncias():
    try:
        items = Denuncia.query.order_by(Denuncia.id.desc()).all()
        return jsonify([i.to_dict() for i in items]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/denuncias", methods=["POST"])
@jwt_required() # AHORA PROTEGIDO
def create_denuncia():
    current_user = get_jwt_identity() # Obtener quién hizo la petición
    data = request.get_json(silent=True) or {}

    correo = current_user # Usamos el correo del token, es más seguro
    descripcion = data.get("descripcion")
    img_b64 = data.get("foto")
    ubicacion = data.get("ubicacion", {})

    if not descripcion or not img_b64:
        return jsonify({"error": "Faltan datos"}), 400

    try:
        if "," in img_b64:
            img_b64 = img_b64.split(",")[1]
        raw_image = base64.b64decode(img_b64, validate=True)
        filename = f"{uuid.uuid4().hex}.jpg"
        file_path = os.path.join(UPLOAD_DIR, filename)
        with open(file_path, "wb") as f:
            f.write(raw_image)
    except Exception as e:
        return jsonify({"error": f"Error imagen: {str(e)}"}), 400

    try:
        nueva = Denuncia(
            correo=correo,
            descripcion=descripcion,
            latitud=ubicacion.get("lat"),
            longitud=ubicacion.get("lng"),
            image_filename=filename
        )
        db.session.add(nueva)
        db.session.commit()
        return jsonify(nueva.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@app.route('/uploads/<filename>')
def serve_image(filename):
    return send_from_directory(UPLOAD_DIR, filename)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
