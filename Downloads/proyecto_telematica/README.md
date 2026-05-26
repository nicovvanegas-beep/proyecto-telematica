# 🖥️ Proyecto Final — Telemática
**Servicio Telemático con Docker + AWS + Terraform**

> Ingeniería en Sistemas e Informática | Tercer Semestre  
> Materia: Telemática

---

## 📋 Descripción

Aplicación web desarrollada en **Python + Flask**, desplegada en **contenedores Docker** sobre una instancia **AWS EC2** aprovisionada automáticamente mediante **Terraform** (Infraestructura como Código).

### Características del servicio

- **Aplicación web** con 3 páginas: Inicio, Servicios y Contacto
- **API REST** con endpoints `/api/status` y `/api/mensajes`
- **Base de datos SQLite** persistente (formulario de contacto)
- **Nginx** como reverse proxy
- **Despliegue automatizado** con un solo comando
- **Infraestructura como código** con Terraform

---

## 🏗️ Arquitectura

```
Internet
    │
    ▼
[AWS EC2 - t2.micro]
    │
    ▼
[Docker Network: app_network]
    ├── [Nginx :80] ──reverse proxy──▶ [Flask/Gunicorn :5000]
    │                                        │
    │                                   [SQLite DB]
    │                                   (volumen persistente)
    └── Archivos estáticos servidos directamente por Nginx
```

### Archivos del proyecto

```
proyecto-telematica/
├── Dockerfile              # Imagen de la app Flask
├── docker-compose.yml      # Orquestación: app + Nginx
├── arquitectura.tf         # Infraestructura AWS con Terraform
├── .gitignore
├── README.md               # Este archivo
├── app/
│   ├── app.py              # Aplicación Flask principal
│   ├── requirements.txt    # Dependencias Python
│   ├── templates/          # HTML (Jinja2)
│   │   ├── base.html
│   │   ├── index.html
│   │   ├── servicios.html
│   │   └── contacto.html
│   └── static/
│       ├── css/style.css
│       └── js/main.js
└── nginx/
    └── nginx.conf          # Configuración del reverse proxy
```

---

## 🚀 Despliegue rápido (local)

### Requisitos
- [Docker](https://docs.docker.com/get-docker/) instalado
- [Docker Compose](https://docs.docker.com/compose/install/) instalado
- Git instalado

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/proyecto-telematica.git
cd proyecto-telematica

# 2. Construir las imágenes y levantar los contenedores
docker-compose up -d --build

# 3. Verificar que los contenedores están corriendo
docker-compose ps

# 4. Abrir la aplicación en el navegador
# http://localhost
```

### Verificar el funcionamiento

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Probar la API de estado
curl http://localhost/api/status

# Detener los contenedores
docker-compose down

# Detener y eliminar volúmenes (borra la base de datos)
docker-compose down -v
```

---

## ☁️ Despliegue en AWS con Terraform

### Requisitos previos

1. **Cuenta AWS activa** (capa gratuita es suficiente)
2. **AWS CLI instalado** → [Instrucciones](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **Terraform instalado** → [Instrucciones](https://developer.hashicorp.com/terraform/downloads)
4. **Key Pair en AWS**: ir a AWS Console → EC2 → Key Pairs → Create key pair
   - Nombre sugerido: `mi-clave-telematica`
   - Guardar el archivo `.pem` en la raíz del proyecto

### Configurar credenciales AWS

```bash
aws configure
# AWS Access Key ID: [tu access key]
# AWS Secret Access Key: [tu secret key]
# Default region name: us-east-1
# Default output format: json
```

> 💡 Las credenciales se obtienen en AWS Console → IAM → Users → Security credentials

### Personalizar variables (opcional)

Editar `arquitectura.tf` y cambiar:
```hcl
variable "key_pair_name" {
  default = "mi-clave-telematica"   # ← nombre de tu key pair
}
```

También cambiar la URL del repositorio en el bloque `user_data`:
```bash
git clone https://github.com/TU_USUARIO/proyecto-telematica.git app
```

### Ejecutar Terraform

```bash
# 1. Inicializar Terraform (descarga el provider de AWS)
terraform init

# 2. Previsualizar qué se va a crear
terraform plan

# 3. Crear la infraestructura en AWS
terraform apply
# Escribir "yes" cuando lo pida

# Al terminar, Terraform muestra:
# ip_publica        = "X.X.X.X"
# url_aplicacion    = "http://X.X.X.X"
# comando_ssh       = "ssh -i mi-clave-telematica.pem ec2-user@X.X.X.X"
```

### Acceder al servidor

```bash
# Conectarse por SSH (ajustar permisos del archivo .pem primero)
chmod 400 mi-clave-telematica.pem
ssh -i mi-clave-telematica.pem ec2-user@<IP_PUBLICA>

# En el servidor, ver los contenedores corriendo
docker ps

# Ver logs de la aplicación
docker-compose -f /home/ec2-user/app/docker-compose.yml logs -f
```

### Destruir la infraestructura (evitar cargos)

```bash
terraform destroy
# Escribir "yes" para confirmar
```

---

## 🔌 API REST

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/status` | Estado del servicio (health check) |
| GET | `/api/mensajes` | Lista todos los mensajes del formulario |

### Ejemplo de respuesta `/api/status`

```json
{
  "status": "ok",
  "servicio": "Proyecto Telemática",
  "timestamp": "2025-01-15T10:30:00.123456",
  "version": "1.0.0"
}
```

---

## 🛠️ Modificar la aplicación

### Agregar una nueva página

1. Crear el template en `app/templates/nueva_pagina.html`:
```html
{% extends "base.html" %}
{% block title %}Nueva Página{% endblock %}
{% block content %}
<h1>Mi nueva página</h1>
{% endblock %}
```

2. Agregar la ruta en `app/app.py`:
```python
@app.route('/nueva-pagina')
def nueva_pagina():
    return render_template('nueva_pagina.html')
```

3. Reconstruir el contenedor:
```bash
docker-compose up -d --build
```

### Agregar una variable de entorno

En `docker-compose.yml`, sección `environment` del servicio `web`:
```yaml
environment:
  - MI_VARIABLE=mi_valor
```

En `app.py`, leerla con:
```python
import os
valor = os.environ.get('MI_VARIABLE', 'valor_por_defecto')
```

---

## 📊 Monitoreo

```bash
# Uso de recursos de los contenedores
docker stats

# Estado de los contenedores
docker-compose ps

# Logs del servicio web
docker-compose logs web

# Logs de Nginx
docker-compose logs nginx
```

---

## 🧰 Tecnologías utilizadas

| Tecnología | Versión | Uso |
|-----------|---------|-----|
| Python | 3.11 | Lenguaje principal |
| Flask | 3.0.3 | Framework web |
| Gunicorn | 22.0.0 | Servidor WSGI de producción |
| SQLite | 3 | Base de datos |
| Docker | 24+ | Contenedores |
| Docker Compose | 2+ | Orquestación |
| Nginx | Alpine | Reverse proxy |
| Terraform | 1.0+ | Infraestructura como código |
| AWS EC2 | t2.micro | Servidor en la nube |

---

## 👤 Autor

**Estudiante:** [Tu Nombre]  
**Carrera:** Ingeniería en Sistemas e Informática  
**Semestre:** Tercero  
**Materia:** Telemática  
**Año:** 2025
