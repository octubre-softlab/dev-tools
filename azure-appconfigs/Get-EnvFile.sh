#!/bin/bash
#clear
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
    -V        #Disable Verbose Mode
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

while getopts "a:h:c:e:lt:vVpo:" option; do
    case $option in
        a)
            SELECTEDAPP=${OPTARG}
            ;;
        h)
            SELECTEDHOST=${OPTARG}
            ;;
        c)
            APPCONFIGSTORENAME=${OPTARG}
            ;;
        e)
            SELECTEDENVIRONMENT=${OPTARG}
            ;;            
        V)
            VERBOSE=1
            ;;
        p)
            PORTAINER=1
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
  [ -z $VERBOSE ] && echo "Ingrese el Azure App Configuration Store name";
  exit 1;
fi

# az login
az configure --defaults appconfig_auth_mode="login"
if [ -z $SELECTEDAPP ] || [ -z $SELECTEDTENANTS ] || [ -z $SELECTEDENVIRONMENT ] || [ -z $SELECTEDHOST ]; then 
  [ -z $VERBOSE ] && echo "Cargando los datos del Azure App Configuration..."

  KEYVALUES=$(az appconfig kv list -n $APPCONFIGSTORENAME --fields key label --all)

  if [ -n $SELECTEDAPP ]; then
    listApps
    [ -z $VERBOSE ] &&  echo "App seleccionado: $SELECTEDAPP" 
    [ -z $VERBOSE ] &&  echo -e "Lista de aplicaciones disponibles: \n $APPS"  
  fi

  if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ]; then
    listTenants
    [ -z $VERBOSE ] &&  echo "Tenant seleccionado: $SELECTEDTENANTS" 
    [ -z $VERBOSE ] &&  echo -e "Lista de tenants disponibles: \n$TENANTS"  
  fi


  if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ]; then
    listEnvironments
    [ -z $VERBOSE ] && echo -e "Ambiente seleccionado: $SELECTEDENVIRONMENT" 
    [ -z $VERBOSE ] && echo -e "Lista de ambientes disponibles: \n$ENVIRONMENTS"  
  fi

  if [ -z $SELECTEDENVIRONMENT ]; then
    [ -z $VERBOSE ] && echo "Te dije que completes los parametros. Ay miguel!"
    exit 1;
  fi
fi
if [ -n $SELECTEDAPP ] && [ -n $SELECTEDTENANTS ] && [ -n $SELECTEDENVIRONMENT ] && [ -n $SELECTEDHOST ]; then 
#Siguiendo el orden de prioridades definido en el repo hago las descargas en las variables KV1,KV2,....KVx  
  [ -z $VERBOSE ] && echo $SELECTEDAPP:$SELECTEDTENANTS@$SELECTEDHOST/$SELECTEDENVIRONMENT
  KV1=$(az appconfig kv list --name appcs-sharedconf2-prd-ue --key "webapi:Common:*" --label '\0' --resolve-keyvault --all)
  KV2=$(az appconfig kv list --name $APPCONFIGSTORENAME --key "$SELECTEDAPP:Common:*" --label "$SELECTEDENVIRONMENT" --resolve-keyvault --all)
  KV3=$(az appconfig kv list --name $APPCONFIGSTORENAME --key "$SELECTEDAPP:$SELECTEDTENANTS:*" --label '\0' --resolve-keyvault --all)
  KV4=$(az appconfig kv list --name $APPCONFIGSTORENAME --key "$SELECTEDAPP:$SELECTEDTENANTS:*" --label "$SELECTEDENVIRONMENT" --resolve-keyvault --all)
  KV5=$(az appconfig kv list --name $APPCONFIGSTORENAME --key "$SELECTEDAPP:$SELECTEDTENANTS@$SELECTEDHOST:*" --label '\0' --resolve-keyvault --all)
  KV6=$(az appconfig kv list --name $APPCONFIGSTORENAME --key "$SELECTEDAPP:$SELECTEDTENANTS@$SELECTEDHOST:*" --label "$SELECTEDENVIRONMENT" --resolve-keyvault --all)
  
  KV1=$(echo $KV1 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:1} ]')
  KV2=$(echo $KV2 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:2} ]')
  KV3=$(echo $KV3 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:3} ]')
  KV4=$(echo $KV4 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:4} ]')
  KV5=$(echo $KV5 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:5} ]')
  KV6=$(echo $KV6 | jq --raw-output '[ .[] | {name:(.key | split(":")[2:] | join("__")), value:("\"" + (.value | gsub("\n";"\\n")) + "\""), level:6} ]')
  
  #Selecciona el mayor nivel de cada clave
  KV=$(echo $KV1$KV2$KV3$KV4$KV5$KV6 | jq -s --raw-output '[.[]| .[]]' | jq 'group_by(.name) | map({ name: (.[0].name), value: .| max_by(.level) | .value}) ')
  [ -z $PORTAINER ] && echo $KV | sed 's/\$/\$\$/g' || echo $KV  | jq --raw-output  '.[] | .name + "=" + .value' | sed 's/\$/\$\$/g'
fi
