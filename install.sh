#!/bin/bash
set -euo pipefail

# ---------------------------
# Variables
# ---------------------------
WEB_ROOT="/var/www/html"
DB_NAME="inventario"
DB_USER="webuser"
DB_PASS="tu_password"
ARCHIVE_URL="https://archive.org/download/inventario_files/inventario_files.zip"
TMP_DIR="/tmp/inventario_install_$$"
TMP_UNZIP="$TMP_DIR/unzip"

# ---------------------------
# Helpers
# ---------------------------
info(){ echo -e "\e[34m[INFO]\e[0m $*"; }
err(){ echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

# ---------------------------
# Instalar dependencias
# ---------------------------
info "Actualizando apt e instalando paquetes necesarios..."
apt update -y
apt install -y apache2 php libapache2-mod-php php-mysqli mariadb-server unzip wget rsync

info "Habilitando e iniciando servicios (apache2, mariadb)..."
systemctl enable apache2
systemctl enable mariadb
systemctl start apache2
systemctl start mariadb

# ---------------------------
# Preparar directorios temporales
# ---------------------------
info "Preparando directorios temporales..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
mkdir -p "$TMP_UNZIP"

# ---------------------------
# Descargar zip desde Archive.org
# ---------------------------
info "Descargando inventario_files.zip desde Archive.org..."
wget -O "$TMP_DIR/inventario_files.zip" "$ARCHIVE_URL"

# ---------------------------
# Descomprimir correctamente
# ---------------------------
info "Descomprimiendo zip..."
unzip -q "$TMP_DIR/inventario_files.zip" -d "$TMP_UNZIP"

# Detectar estructura del ZIP
if [ -d "$TMP_UNZIP/html" ]; then
    RSYNC_SRC="$TMP_UNZIP/html/"
else
    RSYNC_SRC="$TMP_UNZIP/"
fi

info "Copiando archivos a $WEB_ROOT..."
rsync -a "$RSYNC_SRC" "$WEB_ROOT/"

# ---------------------------
# Ajustar permisos
# ---------------------------
info "Ajustando permisos..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# ---------------------------
# Crear base de datos y tabla
# ---------------------------
info "Creando base de datos y usuario en MariaDB..."
SQL=$(cat <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
USE ${DB_NAME};
CREATE TABLE IF NOT EXISTS dispositivos (
  id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(30),
  modelo VARCHAR(50),
  numero_serie VARCHAR(30),
  n_caja VARCHAR(4),
  operatividad TINYINT(1) DEFAULT 1,
  observaciones TEXT,
  area ENUM('Redes','Sinfo','Soportes','Otros'),
  ubicacion_principal VARCHAR(20),
  ubicacion_secundaria VARCHAR(20),
  desplegado TINYINT(1),
  pertenencia_sigle VARCHAR(30),
  noc VARCHAR(50),
  crypto TINYINT(1),
  mac VARCHAR(18),
  red ENUM('MS','NU','WANPG'),
  c_cliente_sinfo VARCHAR(4),
  asignacion ENUM('Linea','Admin','Internet','Cleanpoint'),
  taso TINYINT(1) DEFAULT 0,
  caducidad DATE
);
EOF
)

# Ejecutar SQL con sudo para evitar problemas de autenticación
sudo mysql <<EOF
$SQL
EOF

info "Base de datos y tabla creadas correctamente."

# ---------------------------
# Reiniciar servicios
# ---------------------------
info "Reiniciando Apache y MariaDB..."
systemctl restart apache2
systemctl restart mariadb

IP=$(hostname -I | awk '{print $1}' || echo "localhost")
echo
info "=== INSTALACIÓN COMPLETADA ==="
echo "Web desplegada en: http://${IP}/"
echo "Base de datos: $DB_NAME"
echo "Usuario DB: $DB_USER"
echo "Contraseña DB: $DB_PASS"
