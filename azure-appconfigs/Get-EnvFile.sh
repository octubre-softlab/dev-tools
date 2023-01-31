#!/bin/bash
clear
#set -xe
#Eze querido: 
# Aguante bash! abajo powershell!
#                  Dale no me gusta
#                  si en lugar de hacer un script en bash
#                  corres un container con powershell en linux 
#                  para ejecutar un script roñoso ps1
#                  Basado. https://youtu.be/4_ub6614dwY?t=718
#                  
#                  Firma: el peladonerd

#TODO:
#- [x] usar getops para tomar los parametros (-v version del script, -a app, -t tenant, -e environment, -l listar los objetos, -c configstore -h help que te muestra los comandos)
#- [/] modularizar en funciones el script
#- [ ] hacer distinct del common con las customizaciones del tenant
#- [ ] escapar los key para el .env
#- [ ] dar la opciones en json para dar la opcion de levantar el .json en el switch environment

#Requisitos
#Usar esta imagen: docker pull mcr.microsoft.com/azure-cli
#Tiene todo lo necesario

#Functions section
usage () {
  echo -e " Usage:
    -a        #application to select
    -c        #configstore to use
    -e        #environment (Test/Production) (case sensitive)
    -h        #Displaying help
    -l        #list all objects from an item, example: -l -a
    -o        #Output format
    -t        #tenant to run this script
    -v        #Displaying version
    Example: ./Get-EnvFile.sh -c appcs-sharedconf2-prd-ue -t SUTERH -a webapi"
  exit 1
}

showHelp () {
  echo -e " How to use parameters:
    -a        #application to select. Ex: ./Get-EnvFile.sh -a webapi
    -c        #configstore to use. Ex: ./Get-EnvFile.sh -c appcs-sharedconf2-prd-ue
    -e        #environment (Test/Production) (case sensitive).  Ex: ./Get-EnvFile.sh -e Production
    -o        #Output format: json or env.  Ex: ./Get-EnvFile.sh -o json
    -t        #tenant to run this script. Ex: ./Get-EnvFile.sh -t SUTERH
    How to execute commands:
    -h        #Displaying help
    -l        #list all objects from an item, example: -l -a    
    -v        #Displaying version

    Example: ./Get-EnvFile.sh -c appcs-sharedconf2-prd-ue -t SUTERH -a webapi"
  exit 1
}

listApps() { 
  APPS=$(echo $KEYVALUES | jq --raw-output 'map(.key) | map(. | split(":")[0]) | unique | .[]')
}

listTenants(){
  TENANTS=$(echo $KEYVALUES | jq --raw-output "map(select(.key | split(\":\")[0] == \"$SELECTEDAPP\")) | map(select(.key | split(\":\")[1] | split(\"@\")[0] != \"Common\")) | map(.key) | map(. | split(\":\")[1] | split(\"@\")[0]) | unique | .[]")
}

listEnvironments(){
  ENVIRONMENTS=$(echo $KEYVALUES | jq --raw-output "map(select(.key | split(\":\")[0] == \"$SELECTEDAPP\")) | map(select(.key | split(\":\")[1] | split(\"@\")[0] == \"$SELECTEDTENANTS\")) | map(.label) | unique | .[]")
}

if [[ ${#} -eq 0 ]]; then
   usage
fi

while getopts "a:c:e:hlt:vo:" option; do
    case $option in
        a)
            SELECTEDAPP=${OPTARG}
            ;;
        c)
            APPCONFIGSTORENAME=${OPTARG}
            ;;
        e)
            SELECTEDENVIRONMENT=${OPTARG}
            ;;            
        h)
            showHelp
            ;;
        l)
            echo "Not implemented. Segui participando."
            exit 1;
            ;;
        o) 
            echo "Still in progress. Wait the next sprint."
            exit 1;
            ;;
        t)
            SELECTEDTENANTS=${OPTARG}
            ;;
        v)
            echo "V23.1.14.01.44 - Alta version"
            exit 1;            
            ;;
        ?)
            usage
            ;;
    esac
done

if [ -z $APPCONFIGSTORENAME ]; then
  echo "Ingrese el Azure App Configuration Store name";
  exit 1;
fi

# az login
az configure --defaults appconfig_auth_mode="login"
echo "Cargando los datos del Azure App Configuration..."

KEYVALUES=$(az appconfig kv list -n $APPCONFIGSTORENAME --fields key label --all)

if [ -n $SELECTEDAPP ]; then
  listApps
  echo "App seleccionado: $SELECTEDAPP" 
  echo -e "Lista de aplicaciones disponibles: \n $APPS"  
fi

if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ]; then
  listTenants
  echo "Tenant seleccionado: $SELECTEDTENANTS" 
  echo -e "Lista de tenants disponibles: \n$TENANTS"  
fi


if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ]; then
  listEnvironments
  echo -e "Ambiente seleccionado: $SELECTEDENVIRONMENT" 
  echo -e "Lista de ambientes disponibles: \n$ENVIRONMENTS"  
fi

if [ -z $SELECTEDENVIRONMENT ]; then
  echo "Te dije que completes los parametros. Ay miguel!"
  exit 1;
fi

if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ] && [ -n $SELECTEDENVIRONMENT ]; then 
  echo -e "Vamos a traer la informacion solicitada desde Azure. Aguarde unos instantes y sera atendido."
  TENANTKEYVALUES=$(az appconfig kv list --name $APPCONFIGSTORENAME \
                          --key "$SELECTEDAPP:$SELECTEDTENANTS*" \
                          --label "$SELECTEDENVIRONMENT",\0 \
                          --resolve-keyvault --all)

  echo -e "Espere unos instantes más y sera atendido."
  COMMONTENANTKEYVALUES=$(az appconfig kv list \
                          --name $APPCONFIGSTORENAME \
                          --key "$SELECTEDAPP:Common:*" \
                          --label "$SELECTEDENVIRONMENT",\0 \
                          --resolve-keyvault --all)

  echo $COMMONTENANTKEYVALUES | jq 'map( [(.key | split(":")[2:] | join("__")),.value] | join("=") )| .[]'
  echo $TENANTKEYVALUES | jq 'map( [(.key | split(":")[2:] | join("__")),.value] | join("=") )| .[]'
fi