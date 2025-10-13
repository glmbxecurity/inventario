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


```
