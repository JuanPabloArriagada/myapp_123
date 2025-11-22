import os
import base64
import uuid
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

# ================= CONFIGURACIÓN =================
app = Flask(__name__)
CORS(app) # Permite conexiones desde Flutter (Móvil/Web/Emulador)

# Configuración de base de datos
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'denuncias.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Configuración de carpeta de imágenes
UPLOAD_DIR = os.path.join(basedir, "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

db = SQLAlchemy(app)

# ================= MODELO DE BASE DE DATOS =================
class Denuncia(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    correo = db.Column(db.String(120), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    latitud = db.Column(db.Float, nullable=True)  # Requisito PDF
    longitud = db.Column(db.Float, nullable=True) # Requisito PDF
    image_filename = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        # Genera la URL completa para que Flutter pueda descargar la imagen
        root = request.url_root.rstrip('/')
        return {
            "id": self.id,
            "correo": self.correo,
            "descripcion": self.descripcion,
            "ubicacion": {
                "lat": self.latitud,
                "lng": self.longitud
            },
            "image_url": f"{root}/uploads/{self.image_filename}",
            "fecha": self.created_at.strftime("%Y-%m-%d %H:%M")
        }

# Inicializar la BD al arrancar
with app.app_context():
    db.create_all()

# ================= RUTAS (ENDPOINTS) =================

# 1. RUTA GET: Listar todas las denuncias
@app.route("/api/denuncias", methods=["GET"])
def list_denuncias():
    try:
        items = Denuncia.query.order_by(Denuncia.id.desc()).all()
        return jsonify([i.to_dict() for i in items]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 2. RUTA POST: Crear una nueva denuncia
@app.route("/api/denuncias", methods=["POST"])
def create_denuncia():
    data = request.get_json(silent=True) or {}
    
    # Validar datos obligatorios
    correo = data.get("correo")
    descripcion = data.get("descripcion")
    img_b64 = data.get("foto") 
    ubicacion = data.get("ubicacion", {}) # Llega como {"lat": -33..., "lng": -70...}

    if not correo or not descripcion or not img_b64:
        return jsonify({"error": "Faltan datos obligatorios (correo, descripcion, foto)"}), 400

    # Procesar imagen Base64
    try:
        # Limpiar encabezado si viene (data:image/png;base64,...)
        if "," in img_b64:
            img_b64 = img_b64.split(",")[1]
        
        raw_image = base64.b64decode(img_b64, validate=True)
        
        # Generar nombre único
        filename = f"{uuid.uuid4().hex}.jpg"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        with open(file_path, "wb") as f:
            f.write(raw_image)
            
    except Exception as e:
        return jsonify({"error": f"Error procesando imagen: {str(e)}"}), 400

    # Guardar en Base de Datos
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
        return jsonify({"error": f"Error en BD: {str(e)}"}), 500

# 3. RUTA GET ID: Ver detalle de una denuncia (Requisito PDF)
@app.route("/api/denuncias/<int:id>", methods=["GET"])
def get_denuncia_detail(id):
    item = Denuncia.query.get(id)
    if not item:
        return jsonify({"error": "Denuncia no encontrada"}), 404
    return jsonify(item.to_dict()), 200

# 4. RUTA IMAGEN: Servir las fotos guardadas
@app.route('/uploads/<filename>')
def serve_image(filename):
    return send_from_directory(UPLOAD_DIR, filename)

if __name__ == "__main__":
    # Ejecutar servidor
    app.run(host="0.0.0.0", port=5000, debug=True)