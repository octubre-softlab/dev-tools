oct-template es una herramienta que nos permite clonar repositorios realizando reemplazos de nombres tanto en carpetas y archivos, como así también dentro del contenido de los mismos.
Para descargar la herramienta, debemos situarnos en el directorio donde queremos que quede guardada y ejecutar los siguientes comandos
---- Codigo Bash wget y chmod--
El script se está diseñado para ser ejecutado dentro de la carpeta donde va a quedar guardado nuestro proyecto. En los casos donde sea necesario clonar el repositorio de origen la misma se debe encontrar vacía. Tenga en cuenta también que la herramienta reconfigura el acceso a git para que los cambios se suban a un repositorio distinto al original. Por ello no se recomienda usarlo en una carpeta de trabajo de otro proyecto.
Para clonar un proyecto debemos, inicialmente crear un archivo de configuracion en el cual se definen, las direcciones de los repositorios a utilizar, con sus respectivos branches y también los reemplazos de nombres que se deben realizar tanto en el contenido como en el nombre de los archivos y carpetas. Se puede generar un ejemplo del archivo de configuracion mediante el comnado 
./oct-template.sh –init ../config.json
Nota: Para editar el archivo de configuracion, puede usar nano, vi, vim o code (si está instalado).
Una vez listo y adaptado a nuestras necesidades, procedemos a crear una carpeta vacia la cual va a contener nuestro nuevo proyecto y acceder a la misma mediante:
mkdir NuevoProyecto
cd NuevoProyecto

