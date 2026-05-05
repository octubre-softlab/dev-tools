## TL;DR
```bash
# 1. Generar configuración


bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --init ./config.json

# 2. Editar config.json con tus parámetros

# 3. Crear carpeta destino
mkdir NuevoProyecto

# 4. Simular cambios
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --git-clone --simulate < ./config.json

# 5. Aplicar cambios
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --git-clone < ./config.json
```

## Introducción
oct-template es una herramienta que nos permite clonar repositorios realizando reemplazos de nombres tanto en carpetas y archivos, como así también dentro del contenido de los mismos. 

**Características principales:**
- Clona repositorios en directorios temporales para mayor seguridad
- Reemplaza nombres de archivos, carpetas y contenido
- Genera automáticamente nuevos UUIDs para proyectos .NET
- Copia el resultado final a la carpeta destino especificada
- Modo simulación para previsualizaer cambios


No es necesario descargar la herramienta ya que el comando puedo usarse directamente desde github, pero en caso de desear descargarla, debemos situarnos en el directorio donde queremos que quede guardada y ejecutar los siguientes comandos
```bash
wget https://raw.githubusercontent.com/octubre-softlab/dev-tools/main/Template/oct-template.sh
chmod +x oct-template.sh
```

## Argumentos
```bash
-h --help           # Muestra la ayuda.
-v --version        # Muestra la versión del script (1.2.0-alpha).
-i --init [PATH]    # Genera el archivo de configuración en el path especificado.
-c --git-clone      # Clona el repositorio de origen.
-s --simulate       # Simula los cambios sin aplicarlos.
-q --quiet          # Modo silencioso (menos output).
```

## Configuración
Para clonar un proyecto debemos, inicialmente crear un archivo de configuración en el cual se definen:
- La dirección del repositorio de origen 
- La rama del repositorio (SourceBranch)
- La carpeta destino donde se copiará el resultado final (TargetFolder)
- Los reemplazos de nombres que se deben realizar tanto en el contenido como en el nombre de los archivos y carpetas

Se puede generar un ejemplo del archivo de configuración mediante el comando:
```bash
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) –init ./config.json
```

### Estructura del archivo de configuración
```json
{
  "Source": "https://github.com/usuario/repo-origen.git",
  "SourceBranch": "main", 
  "TargetFolder": "/ruta/absoluta/carpeta-destino",
  "Replacements": [
    {
      "Search": "TextoABuscar",
      "Replace": "TextoDeReemplazo"
    },
    {
      "Search": "OtroTexto", 
      "Replace": "NuevoTexto"
    }
  ]
}
```

>**Nota:** Para editar el archivo de configuración, puede usar nano, vi, vim o code (si está instalado).
## Funcionamiento Interno

La herramienta funciona de la siguiente manera:

1. **Directorio temporal:** Crea un directorio temporal para trabajar de forma segura
2. **Clonado:** Clona el repositorio origen en el directorio temporal
3. **Limpieza:** Remueve la conexión con el repositorio origen
4. **Reemplazos:** 
   - Renombra archivos y carpetas que contengan los textos especificados
   - Reemplaza contenido dentro de archivos (excluyendo .git, node_modules, bin, obj)
   - Genera automáticamente nuevos UUIDs en archivos .csproj
5. **Copia:** Copia el resultado final a la carpeta destino especificada

### Importante
> La carpeta destino debe existir antes de ejecutar el script.
> El script no realiza operaciones git en el destino final (add, commit, push).

## Crear carpeta destino
Una vez listo y adaptado a nuestras necesidades, procedemos a crear la carpeta destino que contendrá nuestro nuevo proyecto:
```bash
mkdir /ruta/completa/NuevoProyecto
```
>**Importante:** Asegúrate de que la ruta en `TargetFolder` del config.json coincida con la carpeta creada.

## Clonar y Simular
Ya listo el archivo de configuración la herramienta permite clonar el repositorio de origen y realizar una simulación sobre los archivos que se van a modificar. Para ello haremos uso de los argumentos --git-clone y --simulate:
```bash
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --git-clone --simulate < config.json
```

### Solo Simular
En caso que necesitemos realizar ajustes en la configuración y deseemos ejecutar nuevamente la simulación, lo podemos realizar eliminando el argumento `--git-clone`. De esta forma la herramienta no va a clonar el repositorio de origen nuevamente, sino que va a asumir que ya existe en el directorio temporal:
```bash
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --simulate < config.json
```

## Aplicar Cambios
Para aplicar los cambios definitivamente:
```bash
bash <(curl -s https://raw.githubusercontent.com/octubre-softlab/dev-tools/refs/heads/main/Template/oct-template.sh) --git-clone < config.json
```

Ejecutando el script de esta manera se realizarán los siguientes cambios:
* Crear un directorio temporal de trabajo
* Clonar el repositorio de origen
* Remover las conexiones con el repositorio de origen
* Reemplazar los nombres de los archivos según lo especificado en el archivo de configuración
* Reemplazar los nombres de las carpetas
* Reemplazar el contenido de los archivos (excluyendo directorios como .git, node_modules, etc.)
* Generar nuevos UUIDs para archivos .csproj
* Copiar todo el contenido procesado a la carpeta destino

## Próximos Pasos
Después de ejecutar la herramienta, puedes:
1. Revisar el contenido de la carpeta destino
2. Inicializar un nuevo repositorio git si es necesario:
   ```bash
   cd /ruta/a/carpeta-destino
   git init
   git add .
   git commit -m "Proyecto importado desde plantilla"
   ```
