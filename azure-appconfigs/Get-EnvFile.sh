#!/bin/bash
#set -e
#Eze querido: 
# Aguante bash! abajo powershell!
#                  Dale no me gusta
#                  si en lugar de hacer un script en bash
#                  corres un container con powershell en linux 
#                  para ejecutar un script roñoso ps1
#                  
#                  Firma: el peladonerd

#TODO:
#- usar getops para tomar los parametros (-v version del script, -a app, -t tenant, -e environment, -l listar los objetos, -h help que te muestra los comandos)
#- modularizar en funciones el script
#- dar la opciones en json para dar la opcion de levantar el .json en el switch environment

#Requisitos
#instalar bash y jq


#APPCONFIGSTORENAME=$1
APPCONFIGSTORENAME="appcs-sharedconf2-prd-ue"
if [[ -z $APPCONFIGSTORENAME ]]; then
  echo "Ingrese el Azure App Configuration Store name";
  exit 1;
fi

# az login
az configure --defaults appconfig_auth_mode="login"
echo "Cargando..."

KEYVALUES=$(az appconfig kv list -n $APPCONFIGSTORENAME --fields key label --all)
APPS=$(echo $KEYVALUES | jq --raw-output 'map(.key) | map(. | split(":")[0]) | unique | .[]')

echo "Seleccione una aplicación"
echo "Aplicaciones:"
SELECTEDAPP=$APPS 
echo $SELECTEDAPP


echo "Seleccione un tenant"
echo "Tenants:"
TENANTS=$(echo $KEYVALUES | jq --raw-output "map(select(.key | split(\":\")[0] == \"$SELECTEDAPP\")) | map(select(.key | split(\":\")[1] | split(\"@\")[0] != \"Common\")) | map(.key) | map(. | split(\":\")[1] | split(\"@\")[0]) | unique | .[]")
SELECTEDTENANTS="SUTERH"
echo "Tenant seleccionado: $SELECTEDTENANTS" 

echo "Seleccione un ambiente"
echo "Ambientes:"
ENVIRONMENTS=$(echo $KEYVALUES | jq --raw-output "map(select(.key | split(\":\")[0] == \"$SELECTEDAPP\")) | map(select(.key | split(\":\")[1] | split(\"@\")[0] == \"$SELECTEDTENANTS\")) | map(.label) | unique | .[]")
SELECTEDENVIRONMENT="Production"
echo "Ambiente seleccionado: $SELECTEDENVIRONMENT"
echo "APP:TENNAT:ENV"

TENANTKEYVALUES=$(az appconfig kv list --name $APPCONFIGSTORENAME \
                        --key "$SELECTEDAPP:$SELECTEDTENANTS*" \
                        --label "$SELECTEDENVIRONMENT",\0 \
                        --resolve-keyvault --all)

COMMONTENANTKEYVALUES=$(az appconfig kv list \
                        --name $APPCONFIGSTORENAME \
                        --key "$SELECTEDAPP:Common:*" \
                        --label "$SELECTEDENVIRONMENT",\0 \
                        --resolve-keyvault --all)

echo $COMMONTENANTKEYVALUES | jq --raw-output 'map( [(.key | split(":")[2:] | join("__")),.value] | join("=") )| .[]'
echo $TENANTKEYVALUES | jq --raw-output 'map( [(.key | split(":")[2:] | join("__")),.value] | join("=") )| .[]'