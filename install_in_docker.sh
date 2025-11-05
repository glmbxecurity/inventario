#!/bin/bash
set -euo pipefail

# ---------------------------
# Variables
# ---------------------------
WEB_ROOT="/var/www/html"
DB_NAME="inventario"
ARCHIVE_URL="https://archive.org/download/inventario_files/inventario_files.zip"
TMP_DIR="/tmp/inventario_install_$$"
TMP_UNZIP="$TMP_DIR/unzip"

# ---------------------------
# Helpers
# ---------------------------
info(){ echo -e "\e[34m[INFO]\e[0m $*"; }
err(){ echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

# Detectar si estamos dentro de Docker o sin systemd
IN_DOCKER=false
if [ -f "/.dockerenv" ] || grep -qE 'docker|containerd' /proc/1/cgroup 2>/dev/null; then
  IN_DOCKER=true
fi

SYSTEMCTL_AVAILABLE=$(command -v systemctl >/dev/null 2>&1 && echo true || echo false)

# ---------------------------
# Instalar dependencias
# ---------------------------
info "Actualizando apt e instalando paquetes necesarios..."
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y apache2 php libapache2-mod-php php-mysqli mariadb-server unzip wget rsync

# ---------------------------
# Iniciar servicios
# ---------------------------
info "Iniciando servicios (apache2, mariadb)..."

if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
  systemctl enable apache2 || true
  systemctl enable mariadb || true
  systemctl start apache2 || true
  systemctl start mariadb || true
else
  # Sin systemd (Docker)
  service apache2 start || /usr/sbin/apache2ctl -D FOREGROUND &
  service mariadb start || mysqld_safe --skip-grant-tables &
  sleep 5
fi

# ---------------------------
# Preparar directorios temporales
# ---------------------------
info "Preparando directorios temporales..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_UNZIP"

# ---------------------------
# Descargar y descomprimir
# ---------------------------
info "Descargando inventario_files.zip desde Archive.org..."
wget -O "$TMP_DIR/inventario_files.zip" "$ARCHIVE_URL"

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
# Credenciales de base de datos
# ---------------------------
if [ -z "${DB_USER:-}" ]; then
  read -p "Introduce el nombre de usuario de la base de datos: " DB_USER
fi

if [ -z "${DB_PASS:-}" ]; then
  read -sp "Introduce la contraseña de la base de datos: " DB_PASS
  echo
fi

DB_NAME=${DB_NAME:-inventario}

# ---------------------------
# Crear base de datos y usuario
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

mysql -u root <<EOF
$SQL
EOF

info "Base de datos y tabla creadas correctamente."

# ---------------------------
# Crear db.php
# ---------------------------
info "Generando archivo db.php..."
cat > "$WEB_ROOT/db.php" <<EOF
<?php
\$host = "localhost";
\$user = "${DB_USER}";
\$pass = "${DB_PASS}";
\$dbname = "${DB_NAME}";
\$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
if (\$conn->connect_error) {
    die("Conexión fallida: " . \$conn->connect_error);
}
\$conn->set_charset("utf8");
?>
EOF

chown www-data:www-data "$WEB_ROOT/db.php"
chmod 640 "$WEB_ROOT/db.php"

# ---------------------------
# Reiniciar servicios
# ---------------------------
info "Reiniciando Apache y MariaDB..."
if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
  systemctl restart apache2 || true
  systemctl restart mariadb || true
else
  service apache2 restart || /usr/sbin/apache2ctl -k graceful
  service mariadb restart || true
fi

IP=$(hostname -I | awk '{print $1}' || echo "localhost")

echo
info "=== INSTALACIÓN COMPLETADA ==="
echo "Web desplegada en: http://${IP}/"
echo "Base de datos: $DB_NAME"
echo "Usuario DB: $DB_USER"
echo "Contraseña DB: $DB_PASS"
