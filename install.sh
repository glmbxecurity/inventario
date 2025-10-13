#!/bin/bash
set -euo pipefail

# ---------------------------
# Variables (ajusta si hace falta)
# ---------------------------
REPO_URL="https://github.com/glmbxecurity/inventario.git"
CLONE_DIR="/tmp/inventario_install_$$"
WEB_ROOT="/var/www/html"
ZIP_NAME="inventario_files.zip"
INSTALL_ZIP="install.zip"
BACKUP_DIR="/var/backups/inventario"
DB_NAME="inventario"
DB_USER="webuser"
DB_PASS="tu_password"

# ---------------------------
# Helpers
# ---------------------------
info(){ echo -e "\e[34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

# ---------------------------
# Actual script
# ---------------------------
info "Actualizando apt e instalando paquetes necesarios..."
apt update -y
apt install -y git unzip apache2 php libapache2-mod-php php-mysqli mariadb-server

info "Habilitando e iniciando servicios (apache2, mariadb)..."
systemctl enable apache2
systemctl enable mariadb
systemctl start apache2
systemctl start mariadb

info "Preparando directorios temporales..."
rm -rf "$CLONE_DIR"
mkdir -p "$CLONE_DIR"
mkdir -p "$BACKUP_DIR"

info "Clonando repo: $REPO_URL -> $CLONE_DIR"
git clone --depth 1 "$REPO_URL" "$CLONE_DIR"

# Comprueba que exista el zip con los ficheros web
if [ ! -f "$CLONE_DIR/$ZIP_NAME" ]; then
    err "No se encontró '$ZIP_NAME' en el repo. Asegúrate de que $ZIP_NAME está en la raíz del repo."
fi

info "Creando backup del contenido actual de $WEB_ROOT"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/webroot_backup_${TIMESTAMP}.tar.gz"
tar -czf "$BACKUP_FILE" -C / "${WEB_ROOT#/}" || warn "No se pudo crear backup completo; puede que la carpeta esté vacía o haya permisos."

info "Vaciando $WEB_ROOT (se conservará el backup en $BACKUP_FILE)"
# BORRA TODO el contenido dentro de WEB_ROOT pero no el directorio en sí
if [ -d "$WEB_ROOT" ]; then
    find "$WEB_ROOT" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
    mkdir -p "$WEB_ROOT"
fi

info "Descomprimiendo $ZIP_NAME en $WEB_ROOT"
unzip -q "$CLONE_DIR/$ZIP_NAME" -d "$WEB_ROOT" || err "Error al descomprimir $ZIP_NAME"

# Si hay un install.zip dentro del repo, lo extraemos en /tmp pero no lo ejecutamos automáticamente
if [ -f "$CLONE_DIR/$INSTALL_ZIP" ]; then
    info "Se ha detectado $INSTALL_ZIP en el repo -> extraído a /tmp (no se ejecuta automáticamente)"
    unzip -q "$CLONE_DIR/$INSTALL_ZIP" -d "/tmp/inventario_install_extra_$TIMESTAMP"
fi

# Generar/sobreescribir db.php con las credenciales configuradas (necesario para tu index.php)
DB_PHP_PATH="$WEB_ROOT/db.php"
info "Generando $DB_PHP_PATH con las credenciales configuradas (se sobrescribirá si existía)"
cat > "$DB_PHP_PATH" <<PHP
<?php
\$servername = "localhost";
\$username = "${DB_USER}";
\$password = "${DB_PASS}";
\$dbname = "${DB_NAME}";

\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);
if (\$conn->connect_error) {
    die("Error de conexión: " . \$conn->connect_error);
}
?>
PHP

# Ajustar permisos
info "Ajustando permisos: owner www-data:www-data y permisos 755 para $WEB_ROOT"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# Crear la base de datos, usuario y tabla en MariaDB
info "Creando base de datos y usuario en MariaDB (DB: $DB_NAME, USR: $DB_USER)"
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

# Intentar ejecutar como root sin contraseña (socket auth). Si falla, mostrar instrucciones.
if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root -e "$SQL"
    info "Base de datos y tabla creadas correctamente."
else
    warn "No se pudo conectar a MariaDB como root sin contraseña. Si tu instalación usa autenticación por contraseña,"
    warn "ejecuta manualmente el siguiente comando (o adapta a tu método de acceso root):"
    echo "----- SQL a ejecutar manualmente -----"
    echo "$SQL"
    echo "--------------------------------------"
fi

info "Reiniciando Apache y MariaDB..."
systemctl restart apache2
systemctl restart mariadb

IP=$(hostname -I | awk '{print $1}' || echo "localhost")
echo
info "=== PROCESO COMPLETADO ==="
echo "Aplicación desplegada en: http://${IP}/"
echo "Backup del webroot guardado en: $BACKUP_FILE"
echo "Base de datos: $DB_NAME"
echo "Usuario DB: $DB_USER"
echo "Contraseña DB: $DB_PASS"
echo
warn "IMPORTANTE: Revisa los ficheros dentro de $WEB_ROOT y asegúrate de que los scripts sensibles (p. ej. install scripts) no hayan sido ejecutados automáticamente."
warn "Si MariaDB usa autenticación root con contraseña, crea la base de datos/usuario manualmente con el SQL mostrado arriba."
info "Si quieres que el script ejecute también otros pasos del '$INSTALL_ZIP', indícamelo y lo incorporo."
