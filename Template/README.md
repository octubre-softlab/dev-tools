## Introducción
oct-template es una herramienta que nos permite clonar repositorios realizando reemplazos de nombres tanto en carpetas y archivos, como así también dentro del contenido de los mismos.
Para descargar la herramienta, debemos situarnos en el directorio donde queremos que quede guardada y ejecutar los siguientes comandos
```bash
wget https://raw.githubusercontent.com/octubre-softlab/dev-tools/main/Template/oct-template.sh
chmod +x replace-template.sh
```
El script se está diseñado para ser ejecutado dentro de la carpeta donde va a quedar guardado nuestro proyecto. En los casos donde sea necesario clonar el repositorio de origen la misma se debe encontrar vacía. Tenga en cuenta también que la herramienta reconfigura el acceso a git para que los cambios se suban a un repositorio distinto al original. Por ello no se recomienda usarlo en una carpeta de trabajo de otro proyecto.

## Argumentos
```bash
-h --help           # Muesta el ayuda.
-v --version        # Muesta la version del script.
-o --init [PATH]    # Genera el archivo de configuracion en el path especificado.
-c --git-clone      # Clona el repositorio de origen.
-p --git-push       # Al finalizar los cambios realiza el push.
-s --simulate       # Simula los cambios.
-q --quiet          # Modo Silencioso
```

## Configuracion
Para clonar un proyecto debemos, inicialmente crear un archivo de configuracion en el cual se definen, las direcciones de los repositorios a utilizar, con sus respectivos branches y también los reemplazos de nombres que se deben realizar tanto en el contenido como en el nombre de los archivos y carpetas. Se puede generar un ejemplo del archivo de configuracion mediante el comnado
```bash
./oct-template.sh –init ./config.json
```
>Nota: Para editar el archivo de configuracion, puede usar nano, vi, vim o code (si está instalado).
### Importante
> El repositorio de destino no debe existir para poder realizar el push correctamente.
> En caso contrario deberá resolver los conflictos que se puedan generar manualmente. Ya sea realizando pull y merge de los cambios. o forzar la reescritura de la historia del repositorio (No recomendado).

## Crear carpeta
Una vez listo y adaptado a nuestras necesidades, procedemos a crear una carpeta vacia la cual va a contener nuestro nuevo proyecto y acceder a la misma mediante:
```bash
mkdir NuevoProyecto
cd NuevoProyecto
```

## Clonar y Simular
Ya listo el archivo de configuracion la herramienta permite clonar el repositorio de origen y realizar una simulacion sobre los archivos que se van a modificar. Para ello haremos uso de los argumentos --git-clone y --simulate
```bash
../oct-template.sh --git-clone --simulate < ../config.json
```
### Solo Simular
En caso que necesitemos realizar ajustes en la configuracion y deseemos ejecutar nuevamente la simulacion, lo podemos realizar eliminando el argumento `--git-clone`. De esta forma la herramiento no va a clonar el repositorio de origen, si no que va a asumir que ya existe en la carpeta actual.
```bash
../oct-template.sh --simulate < ../config.json
```

## Aplicar Cambios
Si nuestro directorio está vacio:
```bash
../oct-template.sh --git-clone < ../config.json
```
Si ya tenemos clonado el proyecto:
```bash
../oct-template.sh < ../config.json
```
Ejecutando el script de esta manera se realizaran los siguientes cambios sobre el directorio:
* Remover las conexiones con el repositorio de origen.
* Configurar el repositorio de destino.
* Reemplazar los nombres de los archivos según lo especificado en el archivo de configuracion.
* Reemplazar los nombres de las carpetas.
* Reemplazar el contenido de los archivos.
* Generar un commit con los cambios realizados.
* Opcionalmente puede realizar el push adicionando el argumento `--git-push`

## Push Manual
Tambien puede realizar el push manualmente usando el siguiente comando:
```bash
git push -u origin --all
```

## Pull y Resolucion de conflictos
### Alternativa 1
En caso de que el repositorio de destino ya exista y por su contenido no se pueda eliminar, la mejor estrategia para resolver este problema es realizar un pull del repositorio objetivo y resolver los confilictos que puedan aparecer. Para realizar el pull puede usar el comando:
```bash
git pull origin TARGET_BRANCH
```

### Alternativa 2
Tambien puede subir los cambios a una rama que actualmente no exista en el repositorio,verificar que todos los cambios realizados sean correctos y una vez listos realizar el merge request correspondiente.