#!/bin/bash
CONFIG_JSON=$(cat $1 )
declare -A r
for row in $( echo "${CONFIG_JSON}" | jq -r '.Replacements[] | "r[\(.Source)]+=\(.Destination)"'); do 
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
NEW_PROJECT_NAME=$( echo "${CONFIG_JSON}" |jq -r '.NewProjectName')
NEW_GIT_REPOSITORY=$( echo "${CONFIG_JSON}" |jq -r '.NewGitRepository')
#---------------------------------Salir si el directorio ya existe
if [ -d "./${NEW_PROJECT_NAME}" ]; then
    printf "${BRed}Directory ${NEW_PROJECT_NAME} already exists. $file ${Color_Off}\n" 
    exit 1
fi
#---------------------------------Clonar Repositorio

    git clone $SOURCE $NEW_PROJECT_NAME
    cd $NEW_PROJECT_NAME
    #Eliminar Conexion con el repositorio del template
    git remote rm origin
    
    git remote add origin $NEW_GIT_REPOSITORY
    #git push -u origin --all
    #git push -u origin --tags

#---------------------------------Reemplazar nombres  / Carpetas
for source in "${!r[@]}"; do
    NEW_NAME="${r[$source]}"
    echo "Repalce Files"
    for file in $(find ./ -type f -name *${source}* -print)
    do
        FILE="${file##*/}"
        # echo "File Path:        ${file}"
        # echo "File Name:        ${file##*/}"
        # echo "New File Name:    ${FILE/$source/$NEW_NAME}"
        # echo "New File Path:    ${file%/*}/${FILE/$source/$NEW_NAME}"
        printf "${Green}mv ${file} ${file%/*}/${FILE/$source/$NEW_NAME}${Color_Off}"
        echo ""
    done

    echo "Repalce Folders"
    find ./ -type d -name *${source}* -printf '%h\0%d\0%p\n' | sort -t '\0' -nr | awk -F '\0' '{print $3}' | while read folder; do
        FOLDER="${folder##*/}"
        #echo "Folder Path:        ${folder}"
        #echo "Folder Name:        ${folder##*/}"
        #echo "New Folder Name:    ${FOLDER/$source/$NEW_NAME}"
        #echo "New Folder Path:    ${folder%/*}/${FOLDER/$source/$NEW_NAME}"
        printf "${Green}mv ${folder} ${folder%/*}/${FOLDER/$source/$NEW_NAME}${Color_Off}"
        echo ""
    done
done
#---------------------------------Reemplazar Contenido archivos
for source in "${!r[@]}"; do
    SED_SCRIPT="s/${source}/${r[$source]}/g"
    for file in $(find ./ -type f -not -path "./.git/*" -and -not -path "./src/frontend/.*" -and -not -path "./src/frontend/node_modules/*" -and -not -path "./tools/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/bin/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/obj/*")
    do 

            printf "${Color_Off}at file $file ${Green}\n"
            eval $(echo "sed --quiet '${SED_SCRIPT}p' $file")
            #eval $(echo "sed -i '${SED_SCRIPT}' $file")
    done
    printf "${Color_Off}"
done


