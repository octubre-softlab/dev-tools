#!/bin/bash
Help(){
    echo "Mostrar ayuda"
    echo ""
    echo ""
    echo ""
}

Config(){
    echo '{"Source":"gitreposource","SourceBranch":"gitbranchsource","Target":"gitrepotarget","TargetBranch":"gitbranchtarget","Replacements":[{"Search":"SearchText","Replace":"ReplaceText"}]}' | jq . > config.json || echo "Archivo de configuracion generado"
}

declare -A FLAGS
# Get the options
while getopts "hivgqps" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) Config
         exit;;
      v)
        echo "Version 1.0.1-alpha"
        exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
      *)
         FLAGS[$option]+=1;;
   esac
done

CONFIG_JSON=$(cat)
declare -A r
for row in $( echo "${CONFIG_JSON}" | jq -r '.Replacements[] | "r[\(.Search)]+=\(.Replace)"'); do 
    eval $(echo ${row}); 
done


#---------------------------------Colores
# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
# Bold
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BWhite='\033[1;37m'       # White

#---------------------------------Leer Configuracion
SOURCE=$( echo "${CONFIG_JSON}" | jq -r '.Source')
SOURCE_BRANCH=$( echo "${CONFIG_JSON}" |jq -r '.SourceBranch')
TARGET=$( echo "${CONFIG_JSON}" |jq -r '.Target')
TARGET_BRANCH=$( echo "${CONFIG_JSON}" |jq -r '.TargetBranch')


#Si existe el parametro -g el directorio de destino no debe existir y realiza el clone del repo
if [[ -v "FLAGS[g]" ]] ; then
    #---------------------------------Salir si el directorio ya existe
    if [ "$(ls -A)" ]; then
        printf "${BRed}The directory is not empty. $file ${Color_Off}\n" 
        exit 1
    fi
    #---------------------------------Clonar Repositorio

    git clone $SOURCE .
    if [[ ! -v "FLAGS[s]" ]]; then
        #Eliminar Conexion con el repositorio del template
        git remote rm origin
        git remote add origin $TARGET
    fi
fi
#---------------------------------Reemplazar nombres  / Carpetas
for source in "${!r[@]}"; do
    NEW_NAME="${r[$source]}"
    FILES=$( echo "find ./ -type f -name \"*${source}*\" -print")
    for file in $(eval $FILES)
    do
        FILE="${file##*/}"
        # echo "File Path:        ${file}"
        # echo "File Name:        ${file##*/}"
        # echo "New File Name:    ${FILE/$source/$NEW_NAME}"
        # echo "New File Path:    ${file%/*}/${FILE/$source/$NEW_NAME}"
        if [[ ! -v "FLAGS[q]" ]] ; then
            printf "${Green}mv ${file} ${file%/*}/${FILE/$source/$NEW_NAME}${Color_Off}"
            echo
        fi
        if [[ ! -v "FLAGS[s]" ]]; then
            eval $(echo mv ${file} ${file%/*}/${FILE/$source/$NEW_NAME})
        fi
    done
    FOLDERS=$( echo "find ./ -type d -name \"*${source}*\" -printf '%h\0%d\0%p\n' | sort -t '\0' -nr | awk -F '\0' '{print \$3}'")
    eval $FOLDERS | while read folder; do
        FOLDER="${folder##*/}"
        #echo "Folder Path:        ${folder}"
        #echo "Folder Name:        ${folder##*/}"
        #echo "New Folder Name:    ${FOLDER/$source/$NEW_NAME}"
        #echo "New Folder Path:    ${folder%/*}/${FOLDER/$source/$NEW_NAME}"
        if [[ ! -v "FLAGS[q]" ]] ; then
            printf "${Green}mv ${folder} ${folder%/*}/${FOLDER/$source/$NEW_NAME}${Color_Off}"
            echo
        fi
        if [[ ! -v "FLAGS[s]" ]]; then
            eval $(echo mv ${folder} ${folder%/*}/${FOLDER/$source/$NEW_NAME}})
        fi
    done
done
#---------------------------------Reemplazar Contenido archivos
for source in "${!r[@]}"; do
    SED_SCRIPT="s/${source}/${r[$source]}/g"
    for file in $(find ./ -type f -not -path "./.git/*" -and -not -path "./src/frontend/.*" -and -not -path "./src/frontend/node_modules/*" -and -not -path "./tools/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/bin/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/obj/*")
    do 
        if [[  ! -v "FLAGS[q]" ]] ; then
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
for file in $(find ./ -type f -name '*.csproj' )
do 
    if [[ ! -v "FLAGS[q]" ]] ; then
        printf "${Color_Off}at file $file ${Green}\n"
        eval $(echo "sed --quiet '${SED_SCRIPT}p' $file")
    fi
    if [[ ! -v "FLAGS[s]" ]]; then
        eval $(echo "sed -i '${SED_SCRIPT}' $file")
    fi
done
printf "${Color_Off}"
#---------------------------------Push Previus Commits in New Repository
if [[ ! -v "FLAGS[s]" && -v "FLAGS[p]" ]]; then
    git push -u origin --all
    git push -u origin --tags
fi
if [[ -v "FLAGS[s]" && -v "FLAGS[g]" ]]; then
    rm -r ./*
    rm -r ./.*
fi
