# ============================================================
# Dockerfile — Imagen de producción para la app Flask
# Proyecto Final Telemática
#
# Construcción:   docker build -t telematica-app .
# Ejecución:      docker run -p 5000:5000 telematica-app
# ============================================================

# Imagen base: Python 3.11 en variante "slim" (más liviana que la completa)
FROM python:3.11-slim

# Metadatos de la imagen
LABEL maintainer="Proyecto Telemática"
LABEL description="Aplicación web Flask desplegada en contenedor Docker"
LABEL version="1.0.0"

# Evitar que Python cree archivos .pyc innecesarios
ENV PYTHONDONTWRITEBYTECODE=1

# Asegurar que los logs se muestren en tiempo real (sin buffer)
ENV PYTHONUNBUFFERED=1

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar solo requirements primero (para aprovechar caché de capas Docker).
# Si el código cambia pero requirements no, Docker reutiliza esta capa.
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código fuente de la aplicación
COPY . .

# Crear el directorio para la base de datos SQLite y asignar permisos
RUN mkdir -p /app/data && chmod 755 /app/data

# Exponer el puerto en el que escucha Gunicorn
EXPOSE 5000

# Comando de arranque:
# gunicorn = servidor WSGI de producción (más robusto que flask run)
# --workers 2 = 2 procesos worker
# --bind 0.0.0.0:5000 = acepta conexiones externas al contenedor
# app:app = módulo "app", objeto Flask llamado "app"
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5000", "app:app"]
