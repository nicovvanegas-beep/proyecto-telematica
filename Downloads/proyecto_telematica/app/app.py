# ============================================================
# app.py — Aplicación web principal (Flask)
# Proyecto Final Telemática
# Descripción: Servidor web con rutas para inicio, servicios,
#              contacto y una API REST básica.
# ============================================================

from flask import Flask, render_template, request, jsonify
import sqlite3
import os
import datetime

# Inicializar la aplicación Flask
app = Flask(__name__)

# Ruta de la base de datos (se crea automáticamente si no existe)
DB_PATH = os.path.join(os.path.dirname(__file__), 'data', 'mensajes.db')


def init_db():
    """Inicializa la base de datos y crea la tabla si no existe."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # Tabla para almacenar mensajes del formulario de contacto
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS mensajes (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre   TEXT NOT NULL,
            email    TEXT NOT NULL,
            mensaje  TEXT NOT NULL,
            fecha    TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()


# ── Rutas HTML ──────────────────────────────────────────────

@app.route('/')
def index():
    """Página de inicio."""
    return render_template('index.html')


@app.route('/servicios')
def servicios():
    """Página de servicios / portafolio."""
    return render_template('servicios.html')


@app.route('/contacto', methods=['GET', 'POST'])
def contacto():
    """
    GET  → muestra el formulario de contacto.
    POST → guarda el mensaje en SQLite y confirma.
    """
    if request.method == 'POST':
        nombre  = request.form.get('nombre', '').strip()
        email   = request.form.get('email', '').strip()
        mensaje = request.form.get('mensaje', '').strip()

        # Validación básica de campos
        if not nombre or not email or not mensaje:
            return render_template('contacto.html',
                                   error='Por favor completa todos los campos.')

        # Guardar en base de datos
        fecha = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        conn = sqlite3.connect(DB_PATH)
        conn.execute('INSERT INTO mensajes (nombre, email, mensaje, fecha) VALUES (?,?,?,?)',
                     (nombre, email, mensaje, fecha))
        conn.commit()
        conn.close()

        return render_template('contacto.html',
                               exito='¡Mensaje enviado correctamente! Te contactaremos pronto.')

    return render_template('contacto.html')


# ── API REST ─────────────────────────────────────────────────

@app.route('/api/status')
def api_status():
    """Endpoint de salud — útil para monitoreo y load balancers."""
    return jsonify({
        'status': 'ok',
        'servicio': 'Proyecto Telemática',
        'timestamp': datetime.datetime.now().isoformat(),
        'version': '1.0.0'
    })


@app.route('/api/mensajes')
def api_mensajes():
    """Retorna todos los mensajes almacenados en formato JSON."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row          # permite acceder columnas por nombre
    rows = conn.execute('SELECT * FROM mensajes ORDER BY id DESC').fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])


# ── Punto de entrada ─────────────────────────────────────────

if __name__ == '__main__':
    init_db()                               # crear DB al arrancar
    # debug=False en producción; host='0.0.0.0' para aceptar conexiones externas
    app.run(host='0.0.0.0', port=5000, debug=False)
