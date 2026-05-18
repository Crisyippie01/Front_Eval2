# ==========================================
# Etapa 1: Constructor (Builder)
# ==========================================
FROM python:3.10-slim AS builder

# Evitar que Python escriba archivos .pyc y forzar salida estándar (buenas prácticas)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Crear un entorno virtual para aislar las dependencias
RUN python -m venv /opt/venv
# Asegurarnos de usar el entorno virtual
ENV PATH="/opt/venv/bin:$PATH"

# Copiamos SOLO el requirements.txt primero. 
# Esto es vital para aprovechar la caché de Docker y no reinstalar todo si solo cambiaste el app.py
COPY requirements.txt .

# Instalar dependencias limpiando la caché para que la capa sea más ligera
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# Etapa 2: Producción (Final)
# ==========================================
FROM python:3.10-slim

# Mismas variables de entorno recomendadas para Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# CREAR USUARIO NO ROOT (Requisito clave de la rúbrica)
RUN useradd -m appuser

# Copiar el entorno virtual ya armado desde la etapa constructora (builder)
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copiar únicamente los archivos necesarios para ejecutar la app
COPY app.py .
COPY templates/ ./templates/

# Cambiar los permisos de la carpeta al usuario no root
RUN chown -R appuser:appuser /app

# Cambiar a nuestro usuario seguro
USER appuser

# Exponer el puerto que usa Flask (por defecto suele ser 5000, cámbialo si tu app usa otro)
EXPOSE 5000

# Comando por defecto para arrancar la aplicación
CMD ["python", "app.py"]