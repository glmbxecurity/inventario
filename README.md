# inventario
Este proyecto instala una BBDD con MariaDB y un frontend web con html + CSS + php para gestionarla. Está diseñado para usarla como inventario de material para cualquier ámbito, especialmente orientado al ET.

## Instalacion
### Requisitos
* Ubuntu Server 22.04 o 24.04 (seguramente funcione en otras versiones sin problema, pero aqui fue testeado y 100% funcional)
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
