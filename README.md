# inventario
Este proyecto instala una BBDD con MariaDB y un frontend web con html + CSS + php para gestionarla. Está diseñado para usarla como inventario de material para cualquier ámbito, especialmente orientado al ET.

## Instalacion
### Requisitos
* Ubuntu Server 22.04 (seguramente funcione en otras verrsiones sin problema, pero aqui fue testeado y 100% funcional)
* Conexion a internet para descargar el material


### Instalacion
Copiar y pegar los siguientes comandos en el terminal
```
sudo apt update && sudo apt upgrade -y
sudo apt install git zip unzip wget -y
git clone https://github.com/glmbxecurity/inventario.git
chmod +x inventario/install.sh
sudo bash ./inventario/install.sh
sudo rm /var/www/html/index.html
```

## Exportar e importar datos
En la propia web, en el apartado de ayuda se puede:
* Exportar el contenido de la BBDD en formato .json
* Importar el contenido de la BBDD en formato .json
* Limpiar todo el contenido de la BBDD

## Imagenes de la web

