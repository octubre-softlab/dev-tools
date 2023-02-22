#!/bin/bash

selectIndex() {
    local list=("$@");

    for i in "${!list[@]}";
    do
        name=$(echo "${list[$i]}" | jq '.name' --raw-output)
        echo "$i. $name"
        i=$((i+1));
    done

    lenght=$(($i-1))

    while [[ 1 ]] ; do
        echo -n "Enter an option: "
        read input
        if [[ "$input" =~ ^[0-$lenght]$ ]] ; then
            break
        fi
    done
    
    return $input;
}

## Select Azure Subscription

subscriptionsJson=$(az account list --all)
readarray -t subscriptions < <(echo $subscriptionsJson | jq -c '.[]')

selectIndex "${subscriptions[@]}"
index=$?

subName=$(echo "${subscriptions[$index]}" | jq '.name' --raw-output)
subId=$(echo "${subscriptions[$index]}" | jq '.id' --raw-output)

az account set --subscription $subId

## Select Azure Resource Group

groupsJson=$(az group list)
readarray -t groups < <(echo $groupsJson | jq -c '.[]')

selectIndex "${groups[@]}"
index=$?

groupName=$(echo "${groups[$index]}" | jq '.name' --raw-output)
groupId=$(echo "${groups[$index]}" | jq '.id' --raw-output)


## Select Azure Key Vault
## TO DO Format: Tags.ApplicationName Tags.Environment (name) 

vaultsJson=$(az resource list --resource-group $groupName --resource-type 'Microsoft.KeyVault/vaults')
readarray -t vaults < <(echo $vaultsJson | jq -c '.[]')

selectIndex "${vaults[@]}"
index=$?

vaultName=$(echo "${vaults[$index]}" | jq '.name' --raw-output)

secretsJson=$(az keyvault secret list --vault-name $vaultName)
readarray -t secrets < <(echo $secretsJson | jq -c '.[]')

GREEN='\033[0;32m'
NC='\033[0m' # No Color
printf "\n${GREEN}Env File${NC}\n\n"

for secret in "${secrets[@]}"; do
    secretName=$(echo "$secret" | jq '.name' --raw-output)    
    secretValue=$(az keyvault secret show --name $secretName --vault-name $vaultName --query value -o tsv)

    envVarName=${secretName//--/__}
    echo "$envVarName=$secretValue"    
done

