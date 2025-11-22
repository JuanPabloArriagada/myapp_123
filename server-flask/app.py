
from flask import Flask, request, jsonify, render_template, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
import base64
import os
import requests
import json
from datetime import datetime

app = Flask(__name__)

# Construir una ruta absoluta para el archivo de la base de datos
basedir = os.path.abspath(os.path.dirname(__file__))
instance_path = os.path.join(basedir, 'instance')

# Asegurarse de que el directorio 'instance' exista
if not os.path.exists(instance_path):
    os.makedirs(instance_path)

# Configuración de la base de datos
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(instance_path, 'denuncias.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Modelo de la base de datos para las denuncias
class Denuncia(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    foto = db.Column(db.String(200), nullable=True) # Guardará la ruta de la imagen
    fecha = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Denuncia {self.id}>'

# Ruta unificada para GET (ver) y POST (crear) denuncias
@app.route('/denuncias', methods=['GET', 'POST'])
def handle_denuncias():
    # --- Lógica para CREAR una denuncia (POST) ---
    if request.method == 'POST':
        data = request.get_json()
        
        if not data or not all(k in data for k in ["nombre", "email", "descripcion"]):
            return jsonify({"error": "Faltan datos en la solicitud"}), 400

        img_b64 = data.get("foto")
        img_path = None
        if img_b64:
            try:
                if ',' in img_b64:
                    header, img_b64 = img_b64.split(',', 1)

                img_data = base64.b64decode(img_b64)
                
                filename = f"denuncia_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
                upload_dir = os.path.join(basedir, 'uploads')
                if not os.path.exists(upload_dir):
                    os.makedirs(upload_dir)
                    
                img_path = os.path.join(upload_dir, filename)
                
                with open(img_path, "wb") as f:
                    f.write(img_data)

            except (ValueError, TypeError) as e:
                return jsonify({"error": f"Error al decodificar la imagen: {e}"}), 400

        try:
            nueva_denuncia = Denuncia(
                nombre=data["nombre"],
                email=data["email"],
                descripcion=data["descripcion"],
                foto=img_path,
                fecha=datetime.utcnow()
            )
            db.session.add(nueva_denuncia)
            db.session.commit()
            return jsonify({"mensaje": "Denuncia creada con éxito", "id": nueva_denuncia.id}), 201

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al guardar en la base de datos: {e}"}), 500

    # --- Lógica para VER todas las denuncias (GET) ---
    if request.method == 'GET':
        denuncias = Denuncia.query.all()
        resultado = []
        for d in denuncias:
            resultado.append({
                'id': d.id,
                'nombre': d.nombre,
                'email': d.email,
                'descripcion': d.descripcion,
                'foto': d.foto,
                'fecha': d.fecha.isoformat()
            })
        return jsonify(resultado)

# Ruta para el formulario de denuncias (CREATE desde web)
@app.route('/denunciar', methods=['GET', 'POST'])
def denunciar():
    if request.method == 'POST':
        nombre = request.form['nombre']
        email = request.form['email']
        descripcion = request.form['descripcion']
        
        foto = request.files.get('foto')
        foto_path = None
        if foto:
            filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{foto.filename}"
            upload_dir = os.path.join(basedir, 'static', 'images')
            if not os.path.exists(upload_dir):
                os.makedirs(upload_dir)
            
            foto_path = os.path.join(upload_dir, filename)
            foto.save(foto_path)
        
        nueva_denuncia = Denuncia(
            nombre=nombre,
            email=email,
            descripcion=descripcion,
            foto=foto_path
        )
        
        db.session.add(nueva_denuncia)
        db.session.commit()
        
        # Redirigir a la lista de denuncias (ahora apunta a la nueva función)
        return redirect(url_for('handle_denuncias'))

    return render_template('denunciar.html')

# Ruta para la página de inicio
@app.route('/')
def index():
    return "Servidor Flask para la app de denuncias"

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    app.run(debug=True, host='0.0.0.0', port=5000)
