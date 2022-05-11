#!/bin/bash
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow

# Bold
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BWhite='\033[1;37m'       # White


Help()
{
   # Display Help
   echo "This script will clone a git repository and try replace the project name"
   echo "We'll asume the follow directory tree"
   echo "."
   echo "├── .devcontainer"
   echo "│   ├── Dockerfile"
   echo "│   └── devcontainer.json"
   echo "├── server-config"
   echo "│   └── docker-compose.yml"
   echo "├── src"
   echo "│   ├── backend"
   echo "│   │   ├── Oct.MyProject"
   echo "│   │   │   ├── .gitignore"
   echo "│   │   │   ├── Controllers"
   echo "│   │   │   ├── Dockerfile"
   echo "│   │   │   ├── Oct.MyProject.csproj"
   echo "│   │   │   ├── Program.cs"
   echo "│   │   │   ├── Properties"
   echo "│   │   │   ├── appsettings.Development.json"
   echo "│   │   │   └── appsettings.json"
   echo "│   │   └── Oct.MyProject.sln"
   echo "│   └── frontend"
   echo "│       ├── .eslintrc.json"
   echo "│       ├── .gitignore"
   echo "│       ├── Dockerfile"
   echo "│       ├── angular.json"
   echo "│       ├── capacitor.config.ts"
   echo "│       ├── docker"
   echo "│       ├── e2e"
   echo "│       ├── ionic.config.json"
   echo "│       ├── karma.conf.js"
   echo "│       ├── node_modules"
   echo "│       ├── package-lock.json"
   echo "│       ├── package.json"
   echo "│       ├── src"
   echo "│       ├── tsconfig.app.json"
   echo "│       ├── tsconfig.json"
   echo "│       └── tsconfig.spec.json"
   echo "├── tools"
   echo "|   └── generate-version.sh"
   echo "├── .gitlab-ci.yml"
   echo "└── README.md"
   echo
   echo "Syntax: scriptTemplate [-s GitRepository | h | v ]"
   echo "options:"
   echo "s     Template git reporsitory. Default https://gitlab.octubre.org.ar/dev/mwa-project-template"
   echo "h     Print this Help."
   echo "v     Verbose replace"
   echo
}




# Get the options
while getopts "hs:v" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      s) # Enter a name
         SOURCE=$OPTARG;;
      v) #Verbose
         VERBOSE=1;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

[ -z "$SOURCE" ] && SOURCE="https://gitlab.octubre.org.ar/dev/mwa-project-template.git"

echo "Hello!, this script will configure your project"

echo "Please Enter the new value, or press ENTER for the default"

TEMPLATE_VAR="Oct.MyProject"
printf "  ${Yellow}Template Variable [${TEMPLATE_VAR}]:${Color_Off}"
read READED_TEMPLATE_VAR
[ ! -z "$READED_TEMPLATE_VAR" ] && TEMPLATE_VAR="$READED_TEMPLATE_VAR"

BACKEND_PROJECT_FOLDER="./src/backend/${TEMPLATE_VAR}"

printf "  ${Yellow}Backend project folder [${BACKEND_PROJECT_FOLDER}]:${Color_Off}" 
read READED_BACKEND_PROJECT_FOLDER
[ ! -z "$READED_BACKEND_PROJECT_FOLDER" ] && BACKEND_PROJECT_FOLDER="${READED_BACKEND_PROJECT_FOLDER/%\//}"

BACKEND_PROJECT_FOLDER=$(echo ${BACKEND_PROJECT_FOLDER})
BACKEND_SOLUTION_FILE="${BACKEND_PROJECT_FOLDER}.sln"
PROJECT_FILE=$(echo "${BACKEND_PROJECT_FOLDER}" | awk -F/ '{ print $NF }')
BACKEND_PROJECT_FILE="${BACKEND_PROJECT_FOLDER}/${PROJECT_FILE}.csproj"

printf "  ${Yellow}Backend solution file [${BACKEND_SOLUTION_FILE}]:${Color_Off}" 
read READED_BACKEND_SOLUTION_FILE
[ ! -z "$READED_BACKEND_SOLUTION_FILE" ] && BACKEND_SOLUTION_FILE="$READED_BACKEND_SOLUTION_FILE"
printf "  ${Yellow}Backend project file [${BACKEND_PROJECT_FILE}]:${Color_Off}" 
read READED_BACKEND_PROJECT_FILE
[ ! -z "$READED_BACKEND_PROJECT_FILE" ] && BACKEND_PROJECT_FILE="$READED_BACKEND_PROJECT_FILE"

printf "  ${Yellow}New project name:${Color_Off}" 
read NEW_PROJECT_NAME
if [ -z "${NEW_PROJECT_NAME// }" ]; then
    echo -e "${BRed}New project name must not be empty"
    exit -1
fi

echo ""
echo "Configuracion resultante:"
echo "* Template Variable:        ${TEMPLATE_VAR}"
echo "* Backend project folder:   ${BACKEND_PROJECT_FOLDER}"
echo "* Backend solution file:    ${BACKEND_SOLUTION_FILE}"
echo "* Backend project file:     ${BACKEND_PROJECT_FILE}"
echo "* New project name:         ${NEW_PROJECT_NAME}"

printf "${BWhite}is it correct? Y/n "
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then

    #Clonar repositorio
    git clone $SOURCE $NEW_PROJECT_NAME
    cd $NEW_PROJECT_NAME
    #Eliminar Conexion con el repositorio del template
    git remote remove origin

    echo "Renaming files and directories..."
    #Reemplazar nombres de archivos
    eval $(echo "mv ${BACKEND_SOLUTION_FILE} ${BACKEND_SOLUTION_FILE%/*}/${NEW_PROJECT_NAME}.sln")
    eval $(echo "mv ${BACKEND_PROJECT_FOLDER} ${BACKEND_PROJECT_FOLDER%/*}/${NEW_PROJECT_NAME}")
    eval $(echo "mv ${BACKEND_PROJECT_FOLDER%/*}/${NEW_PROJECT_NAME}/${BACKEND_PROJECT_FILE##*/} ${BACKEND_PROJECT_FOLDER%/*}/${NEW_PROJECT_NAME}/${NEW_PROJECT_NAME}.csproj")

    echo "Replacing files's content..."
    SED_SCRIPT="s/${TEMPLATE_VAR}/${NEW_PROJECT_NAME}/g"
    for file in $(find ./ -type f -not -path "./.git/*" -and -not -path "./src/frontend/.*" -and -not -path "./src/frontend/node_modules/*" -and -not -path "./tools/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/bin/*"  -and -not -path "./src/backend/${TEMPLATE_VAR}/obj/*")
    do 
        if [ ! -z "$VERBOSE" ]; then
            printf "${Color_Off}at file $file ${Green}\n"
            eval $(echo "sed --quiet '${SED_SCRIPT}p' $file")
        fi
        eval $(echo "sed -i '${SED_SCRIPT}' $file")
    done
    echo "Finished."

fi



