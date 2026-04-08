#!/bin/bash
Help() {
    echo "oct-template es una herramienta que nos permite clonar repositorios realizando reemplazos de nombres tanto en carpetas y archivos, como asi tambien dentro del contenido de los mismos"
    echo ""
    echo ""
    echo ""
}

Config() {
    echo '{"Source":"gitreposource","SourceBranch":"gitbranchsource","TargetFolder":"targetfolder","Replacements":[{"Search":"SearchText","Replace":"ReplaceText"}]}' | jq . >${1} || echo "Archivo de configuracion generado"
}

declare -A FLAGS

ARGUMENT_LIST=(
    "help"
    "git-clone"
    "simulate"
    "init:"
    "version"
    "quiet"
)
OPTION_LIST=(
    "h"
    "c"
    "s"
    "i:"
    "v"
    "q"
)

# read arguments
opts=$(
    getopt \
        --longoptions "$(printf "%s," "${ARGUMENT_LIST[@]}")" \
        --name "$(basename "$0")" \
        --options "$(printf "%s," "${OPTION_LIST[@]}")" \
        -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help) # display Help
        Help
        exit
        ;;
    -i | --init)
        Config $2
        exit
        ;;
    -v | --version)
        echo "Version 1.2.0-alpha"
        exit
        ;;
    -c | --git-clone)
        echo "git clone"
        FLAGS["g"]+=1
        shift 1
        ;;
    -s | --simulate)
        echo "Simular"
        FLAGS["s"]+=1
        shift 1
        ;;
    -q | --quiet)
        echo "Quiet"
        FLAGS["q"]+=1
        shift 1
        ;;
    *)
        shift 1
        ;;
    esac
done

CONFIG_JSON=$(cat)

declare -A r
for row in $(echo "${CONFIG_JSON}" | jq -r '.Replacements[] | "r[\(.Search)]+=\(.Replace)"'); do
    eval $(echo ${row})
done

#---------------------------------Colores
# Reset
Color_Off='\033[0m' # Text Reset
# Regular Colors
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
# Bold
BRed='\033[1;31m'   # Red
BGreen='\033[1;32m' # Green
BWhite='\033[1;37m' # White

#---------------------------------Leer Configuracion
SOURCE=$(echo "${CONFIG_JSON}" | jq -r '.Source')
SOURCE_BRANCH=$(echo "${CONFIG_JSON}" | jq -r '.SourceBranch')
TARGET_FOLDER=$(echo "${CONFIG_JSON}" | jq -r '.TargetFolder')

# Crea un directorio temporal y guarda la ruta en una variable
temp_dir=$(mktemp -d)

echo "Directorio temporal creado en: $temp_dir"
cd $temp_dir

git clone $SOURCE .
git checkout $SOURCE_BRANCH
rm .git -rf

#---------------------------------Reemplazar nombres  / Carpetas
for source in "${!r[@]}"; do
    NEW_NAME="${r[$source]}"
    FILES=$(echo "find ./ -type f -name \"*${source}*\" -print")
    for file in $(eval $FILES); do
        FILE="${file##*/}"
        # echo "File Path:        ${file}"
        # echo "File Name:        ${file##*/}"
        # echo "New File Name:    ${FILE/$source/$NEW_NAME}"
        # echo "New File Path:    ${file%/*}/${FILE/$source/$NEW_NAME}"
        if [[ ! -v "FLAGS[q]" ]]; then
            printf "${Green}mv ${file} ${file%/*}/${FILE/$source/$NEW_NAME}${Color_Off}"
            echo
        fi
        if [[ ! -v "FLAGS[s]" ]]; then
            eval $(echo mv ${file} ${file%/*}/${FILE/$source/$NEW_NAME})
        fi
    done
    FOLDERS=$(echo "find ./ -type d -name \"*${source}*\" -printf '%h\0%d\0%p\n' | sort -t '\0' -nr | awk -F '\0' '{print \$3}'")
    eval $FOLDERS | while read folder; do
        FOLDER="${folder##*/}"
        #echo "Folder Path:        ${folder}"
        #echo "Folder Name:        ${folder##*/}"
        #echo "New Folder Name:    ${FOLDER/$source/$NEW_NAME}"
        #echo "New Folder Path:    ${folder%/*}/${FOLDER/$source/$NEW_NAME}"
        if [[ ! -v "FLAGS[q]" ]]; then
            printf "${Green}mv ${folder} ${folder%/*}/${FOLDER/$source/$NEW_NAME}${Color_Off}"
            echo
        fi
        if [[ ! -v "FLAGS[s]" ]]; then
            eval $(echo mv ${folder} ${folder%/*}/${FOLDER/$source/$NEW_NAME})
        fi
    done
done
#---------------------------------Reemplazar Contenido archivos
for source in "${!r[@]}"; do
    SED_SCRIPT="s/${source}/${r[$source]}/g"
    for file in $(find ./ -type f -not -path "./.git/*" -and -not -path "./src/frontend/.*" -and -not -path "./src/frontend/node_modules/*" -and -not -path "./tools/*" -and -not -path "./src/backend/${TEMPLATE_VAR}/bin/*" -and -not -path "./src/backend/${TEMPLATE_VAR}/obj/*"); do
        if [[ ! -v "FLAGS[q]" ]]; then
            printf "${Color_Off}at file $file ${Green}\n"
            eval $(echo "sed --quiet '${SED_SCRIPT}p' $file")
        fi
        if [[ ! -v "FLAGS[s]" ]]; then
            eval $(echo "sed -i '${SED_SCRIPT}' $file")
        fi
    done
    printf "${Color_Off}"
done
#Reemplazar UUID
SED_SCRIPT="s/<UserSecretsId>[a-fA-F0-9]\{8\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{12\}<\/UserSecretsId>/<UserSecretsId>$(uuidgen)<\/UserSecretsId>/g"
for file in $(find ./ -type f -name '*.csproj'); do
    if [[ ! -v "FLAGS[q]" ]]; then
        printf "${Color_Off}at file $file ${Green}\n"
        eval $(echo "sed --quiet '${SED_SCRIPT}p' $file")
    fi
    if [[ ! -v "FLAGS[s]" ]]; then
        eval $(echo "sed -i '${SED_SCRIPT}' $file")
    fi
done
printf "${Color_Off}"
# Copiar contenido a carpeta destino TARGET_FOLDER
shopt -s dotglob
cp -r ./* "$TARGET_FOLDER"
shopt -u dotglob
# #---------------------------------Push Previus Commits in New Repository

# git add .
# git commit -m "Project imported"

