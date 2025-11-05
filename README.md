# inventario
Este proyecto instala una BBDD con MariaDB y un frontend web con html + CSS + php para gestionarla. Está diseñado para usarla como inventario de material para cualquier ámbito, especialmente orientado al ET.

## Instalacion
### Requisitos
* Ubuntu Server 22.04 o 24.04 (seguramente funcione en otras versiones sin problema, pero aqui fue testeado y 100% funcional)
* Conexion a internet para descargar el material


### Instalacion en MV, LXC, Baremetal
Copiar y pegar los siguientes comandos en el terminal
```
sudo apt update && sudo apt upgrade -y
sudo apt install git zip unzip wget -y
git clone https://github.com/glmbxecurity/inventario.git
chmod +x inventario/install.sh
sudo bash ./inventario/install.sh
sudo rm /var/www/html/index.html
```
### Instalacion en Docker
Si lo quieres instalar en un docker, por querer hacerlo exportable, por ejemplo, usa estos comandos:  

##### Crear dockerfile
crea un directorio, y dentro de este el fichero Dockerfile con el siguiente contenido:  
```bash
# Imagen base: Ubuntu Server 24.04 (Noble)
FROM ubuntu:24.04

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el sistema base
RUN apt update && apt upgrade -y && apt install -y \
    sudo \
    vim \
    curl \
    wget \
    net-tools \
    && apt clean

# Comando por defecto
CMD ["bash"]

```
##### Crear el docker como tal
```bash
docker build -t ubuntu24:base .

# Verificar la imagen
docker images

# Lanzar contenedor y entrar a personalizar
docker run -it ubuntu24:base
```
##### Instalar en docker (opcional)
Instalar el serivicio en el docker:  
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git zip unzip wget -y
git clone https://github.com/glmbxecurity/inventario.git
chmod +x inventario/install_in_docker.sh
sudo bash ./inventario/install_in_docker.sh
sudo rm /var/www/html/index.html
```
### Exportar e Importar docker
Si quieres exportar el docker para poderlo llevar a otro entorno, debes hacer lo siguiente:

```bash
# Comprobar el id del contendor
docker ps -a

# Crear la imagen docker
docker commit abcd1234efgh ubuntu24:custom

# Exportar la imagen a un fichero tar
docker save -o ubuntu24_custom.tar ubuntu24:custom

# Importar la imagen en otro entorno
docker load -i ubuntu24_custom.tar

# lanzar el contenedor de la imagen customizada
docker run -it ubuntu24:custom
```

#### lanzar el contenedor de la imagen customizada con datos persistentes
Nos interesa realmente la BBDD en este caso. Para ello debemos crear un directorio en el host para tal efecto,  
y luego lanzar el contenedor de la siguiente manera:  
```bash
docker run -d \
  --name inventario_db \
  --restart unless-stopped \
  -v /home/admin/inventario/bbdd:/var/lib/mysql \
  ubuntu24:custom
```



## Como exportar e importar datos a la BBBDD
En la propia web, en el apartado de ayuda se puede:
* Exportar el contenido de la BBDD en formato .json
* Importar el contenido de la BBDD en formato .json
* Limpiar todo el contenido de la BBDD

## Caracteristicas y Screenshots
* Visualizacion de inventario con filtros de búsqueda
* Posibilidad de agregar, eliminar y modificar elementos del inventario
* Exportar inventario a CSV (si filtras, se exporta solo lo filtrado, asi se puede sacar datos de manera personalizada)
* Exportar inventario a PDF (si filtras, se exporta solo lo filtrado, asi se puede sacar datos de manera personalizada)
* Exportar inventario a PDF con formato de relevo de material
* Importar, exportar y vaciar datos de la BBDD

![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/1_inicio.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/2_busqueda.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/3_agregar.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/4_export_csv.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/5_export_pdf.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/6_export_pdf_relevo.png)
![image](https://raw.githubusercontent.com/glmbxecurity/inventario/refs/heads/main/images/7_pdf.png)
