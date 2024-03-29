#!/bin/bash
#set -xe

# Source code https://github.com/octubre-softlab/dev-tools/blob/main/deploy-portainer/deploy-portainer.sh

#### bash azure-appconfigs/Get-EnvFile.sh -c appcs-sharedconf2-prd-ue -e Production -a webapi -V -t OctubreOSPERYH -h ndc-lnx-as-11 | bash deploy-portainer/deploy-portainer.sh -u ballesteros.d -p TuPasswordMiguel! -h ndc-lnx-as-11 -c webapi-cajasoctubre-production -f compose_apps/webapi/prod-linux/docker-compose.OctubreOSPERYH.Production.yml
####

[ ! -t 0 ] && INPUT=$(cat) || INPUT=""
VARIABLES_JSON=$(echo $INPUT | jq --raw-output .)

while getopts "u:Pp:h:r:lc:uf:d:a:k:V" option; do
    case $option in
        u)
            USER=${OPTARG}
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        a)
            PORTAINER_ADDRESS=${OPTARG}
            ;;
        k)
            API_KEY=${OPTARG}
            ;;
        h)
            HOST=${OPTARG}
            ;;
        r)
            REPOSITORY_URL=${OPTARG}
            ;;
        f)
            COMPOSE_FILE=${OPTARG}
            ;;
        V)
            VERBOSE=1
            ;;
        P)
            # this will take password letter by letter
            while read -r -t 0; do read -r; done
            while IFS= read -p "$pass_var" -r -s -n 1 letter
            do
                # if you press enter then the condition 
                # is true and it exit the loop
                if [[ $letter == $'\0' ]]
                then
                    break
                fi
                
                # the letter will store in password variable
                PASSWORD="$letter"
                
                # in place of password the asterisk (*) 
                # will printed
                pass_var="*"
            done
            ;;
        l)
            LIST_STACKS=1
            ;;
        c)
            CREATE_STACK=1
            STACK_NAME=${OPTARG}
            ;;
        d)
            DESTROY_STACK=1
            STACK_NAME=${OPTARG}
            ;;
        ?)
            usage
            ;;
    esac
done


login()
{
    if [ -n $API_KEY ]; then
        AUTHORIZATION=$(echo X-API-Key:$API_KEY)
    else
        if [ -n $USER ] && [ -n $PASSWORD ]; then
            #Login / Get Token
            TOKEN=$(curl -s --location "$PORTAINER_ADDRESS/api/auth" --header 'Content-Type: application/json' --data "{\"username\":\"$USER\",\"password\":\"$PASSWORD\"}" | jq --raw-output '.jwt')
            AUTHORIZATION=$(echo "Authorization: Bearer $TOKEN")
            #echo $TOKEN
        else
            echo "Invalid Credentials (empty)"
            exit 127;
        fi

        if [ "$TOKEN" = "null" ]; then
            echo "Invalid Credentials (no token)"
            exit 127;
        fi
    fi
}

list_stacks()
{
    [ -z $AUTHORIZATION ] && login
    ENDPOINTID=$(curl -s --location "$PORTAINER_ADDRESS/api/endpoints" --header "$AUTHORIZATION" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    curl -s --location "$PORTAINER_ADDRESS/api/stacks" --header "$AUTHORIZATION" | jq --raw-output " .[] | select(.EndpointId == $ENDPOINTID)"
}

list_endpoints()
{
  [ -z $AUTHORIZATION ] && login
  curl -s --location "$PORTAINER_ADDRESS/api/endpoints" --header "$AUTHORIZATION" | jq --raw-output ".[] | .Name"
}

create_or_update_stack()
{
    echo "Create or Update $1"
    EXISTS=$(list_stacks | jq "select(.Name == \"$1\") | .Id") 
    if [[ -z "$EXISTS" ]]; then
        create_stack $1
    elif [[ -n "$EXISTS" ]]; then
        update_stack $1
    fi
}
#Nombre del stack, base git, compose file, (user,pass, variables y host ya existen)
create_stack()
{
    if [[ -z $VARIABLES_JSON ]]; then
        echo "Variables Undefined"
        exit 127;
    fi
    if [ -z $COMPOSE_FILE ]; then
        echo "ComposeFile Undefined"
        exit 127;
    fi
    echo "Create_Stack $1"
    [ -z $AUTHORIZATION ] && login
    [ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location "$PORTAINER_ADDRESS/api/endpoints" --header "$AUTHORIZATION" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    #echo "$ENDPOINTID"
    #echo "$AUTHORIZATION"
    DATA=$(echo "{
        \"Name\": \"$1\",
        \"RepositoryURL\": \"$REPOSITORY_URL\",
        \"RepositoryReferenceName\": \"\",
        \"ComposeFile\": \"$COMPOSE_FILE\",
        \"AdditionalFiles\": [],
        \"RepositoryAuthentication\": true,
        \"RepositoryUsername\": \"$USER\",
        \"RepositoryPassword\": \"$PASSWORD\",
        \"Env\": $VARIABLES_JSON
        }" | jq -c '.')
    [ -n "$VERBOSE" ] && echo $DATA
    RESPONSE=$(echo $DATA |
       curl -s -D - "$PORTAINER_ADDRESS/api/stacks?endpointId=$ENDPOINTID&method=repository&type=2" \
       -H "$AUTHORIZATION" \
       -H 'content-type: application/json' \
       --data @-)
    http_status=$(echo "$RESPONSE" | grep -Fi "HTTP/" | awk '{print $2}')
    response_body=$(echo "$RESPONSE" | awk '/^\r$/ { body=1; next } body { print }')

    echo "HTTP Status: $http_status"
    
    # Si VERBOSE tiene valor o http_status esta fuera del rango 200, mostrar body
    if [ -n "$VERBOSE" ] || [ "$http_status" -lt 200 -o "$http_status" -ge 300 ]; then
        echo "Response Body: $response_body"
    fi

}

update_stack()
{
    [ -n "$VERBOSE" ] && echo "Update_Stack $1"
    STACK=$(list_stacks | jq --raw-output "select(.Name == \"$1\")")
    STACKID=$(echo $STACK | jq --raw-output ".Id")
    STACK_DEPLOYER=$(echo $STACK | jq --raw-output '.GitConfig.Authentication.Username')
    [ -z "$VARIABLES_JSON" ] && VARIABLES_JSON=$(echo $STACK | jq --raw-output '.Env')
    [ -z $AUTHORIZATION ] && login
    [ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location "$PORTAINER_ADDRESS/api/endpoints" --header "$AUTHORIZATION" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    [ -n "$VERBOSE" ] && echo "$ENDPOINTID"
    [ -n "$VERBOSE" ] && echo "$AUTHORIZATION"
    [ -n "$VERBOSE" ] && echo "$STACKID"
    [ -n "$VERBOSE" ] && echo "$STACK_DEPLOYER"
    DATA=$( echo "{
        \"prune\": false,
        \"RepositoryUsername\": \"$STACK_DEPLOYER\",
        \"PullImage\":true,
        \"RepositoryAuthentication\":true,
        \"Env\": $VARIABLES_JSON
    }" | jq -c '.' )
    [ -n "$VERBOSE" ] && echo $DATA
    RESPONSE=$(echo $DATA |
        curl -s -D - "$PORTAINER_ADDRESS/api/stacks/$STACKID/git/redeploy?endpointId=$ENDPOINTID" \
        -X 'PUT' \
        -H "$AUTHORIZATION" \
        -H 'content-type: application/json' \
        --data @-)
    # echo "$RESPONSE"
    http_status=$(echo "$RESPONSE" | grep -Fi "HTTP/" | awk '{print $2}')
    response_body=$(echo "$RESPONSE" | awk '/^\r$/ { body=1; next } body { print }')

    echo "HTTP Status: $http_status"
    
    # Si VERBOSE tiene valor o http_status esta fuera del rango 200, mostrar body
    if [ -n "$VERBOSE" ] || [ "$http_status" -lt 200 -o "$http_status" -ge 300 ]; then
        echo "Response Body: $response_body"
    fi
}

delete_stack()
{
    [ -n "$VERBOSE" ] && echo "Delete_Stack $1"
    STACK=$(list_stacks | jq --raw-output "select(.Name == \"$1\")")
    STACKID=$(echo $STACK | jq --raw-output ".Id")
    [ -z $AUTHORIZATION ] && login
    [ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location "$PORTAINER_ADDRESS/api/endpoints" --header "$AUTHORIZATION" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    [ -n "$VERBOSE" ] && echo "$ENDPOINTID"
    [ -n "$VERBOSE" ] && echo "$AUTHORIZATION"
    [ -n "$VERBOSE" ] && echo "$STACKID"
    [ -n "$VERBOSE" ] && echo $DATA
    RESPONSE=$(curl -s -D - "$PORTAINER_ADDRESS/api/stacks/$STACKID?endpointId=$ENDPOINTID&external=false" \
        -X 'DELETE' \
        -H $AUTHORIZATION \
        -H 'content-type: application/json')
    
    http_status=$(echo "$RESPONSE" | grep -Fi "HTTP/" | awk '{print $2}')
    response_body=$(echo "$RESPONSE" | awk '/^\r$/ { body=1; next } body { print }')

    echo "HTTP Status: $http_status"
    
    # Si VERBOSE tiene valor o http_status esta fuera del rango 200, mostrar body
    if [ -n "$VERBOSE" ] || [ "$http_status" -lt 200 -o "$http_status" -ge 300 ]; then
        echo "Response Body: $response_body"
    fi
}

if [ -z $HOST ]; then
    echo "Host undefined"
    list_endpoints
    exit 127;
fi

if [[ $LIST_STACKS -eq 1 ]]; then
    list_stacks | jq --raw-output '.Name'
fi

if [[ $CREATE_STACK -eq 1 ]]; then
    create_or_update_stack $STACK_NAME
fi

if [[ $DESTROY_STACK -eq 1 ]]; then
    delete_stack $STACK_NAME
fi

