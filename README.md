# inventario
Este proyecto instala una BBDD con MariaDB y un frontend web con html + CSS + php para gestionarla. Está diseñado para usarla como inventario de material para cualquier ámbito, especialmente orientado al ET.

## Instalacion
### Requisitos
* Ubuntu Server 22.04 (seguramente funcione en otras verrsiones sin problema, pero aqui fue testeado y 100% funcional)
* Conexion a internet para descargar el material
* CA y Proxy (opcional, para certificar el sitio web)(Sin proxy tambien se puede)
* DNS (opcional, para darle un nombre de dominio al sitio web)

### Instalacion
Copiar y pegar los siguientes comandos en el terminal
```
sudo apt update && sudo apt upgrade -y
sudo apt install git zip unzip -y
git clone https://github.com/glmbxecurity/inventario.git
sudo unzip ./inventario/inventario_files.zip -d /

```
