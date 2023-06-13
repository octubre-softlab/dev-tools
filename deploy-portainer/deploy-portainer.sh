#!/bin/bash
#set -xe

#### bash azure-appconfigs/Get-EnvFile.sh -c appcs-sharedconf2-prd-ue -e Production -a webapi -V -t OctubreOSPERYH -h ndc-lnx-as-11 | bash deploy-portainer/deploy-portainer.sh -u ballesteros.d -p TuPasswordMiguel! -h ndc-lnx-as-11 -c webapi-cajasoctubre-production -f compose_apps/webapi/prod-linux/docker-compose.OctubreOSPERYH.Production.yml
####

[ ! -t 0 ] && INPUT=$(cat) || INPUT=""
VARIABLES_JSON=$(echo $INPUT | jq --raw-output .)

while getopts "u:Pp:h:lc:uf:d:" option; do
    case $option in
        u)
            USER=${OPTARG}
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        h)
            HOST=${OPTARG}
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
    if [ -n $USER ] && [ -n $PASSWORD ]; then
        #Login / Get Token
        TOKEN=$(curl -s --location 'https://portainer.octubre.org.ar/api/auth' --header 'Content-Type: application/json' --data "{\"username\":\"$USER\",\"password\":\"$PASSWORD\"}" | jq --raw-output '.jwt')
        #echo $TOKEN
    else
        echo "Invalid Credentials (empty)"
        exit 127;
    fi

    if [ "$TOKEN" = "null" ]; then
        echo "Invalid Credentials (no token)"
        exit 127;
    fi
}

list_stacks()
{
    [ -z $TOKEN ] && login
    ENDPOINTID=$(curl -s --location 'https://portainer.octubre.org.ar/api/endpoints' --header "Authorization: Bearer $TOKEN" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    curl -s --location 'https://portainer.octubre.org.ar/api/stacks' --header "Authorization: Bearer $TOKEN" | jq --raw-output " .[] | select(.EndpointId == $ENDPOINTID)"
}

list_endpoints()
{
  [ -z $TOKEN ] && login
  curl -s --location 'https://portainer.octubre.org.ar/api/endpoints' --header "Authorization: Bearer $TOKEN" | jq --raw-output ".[] | .Name"
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
    [ -z $TOKEN ] && login
    [ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location 'https://portainer.octubre.org.ar/api/endpoints' --header "Authorization: Bearer $TOKEN" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    #echo "$ENDPOINTID"
    #echo "$TOKEN"
    DATA=$(echo "{
        \"Name\": \"$1\",
        \"RepositoryURL\": \"https://gitlab.octubre.org.ar/dev/apps-deployments.git\",
        \"RepositoryReferenceName\": \"\",
        \"ComposeFile\": \"$COMPOSE_FILE\",
        \"AdditionalFiles\": [],
        \"RepositoryAuthentication\": true,
        \"RepositoryUsername\": \"$USER\",
        \"RepositoryPassword\": \"$PASSWORD\",
        \"Env\": $VARIABLES_JSON
        }" | jq -c '.')
      #echo $DATA
       echo $DATA |
       curl -i "https://portainer.octubre.org.ar/api/stacks?endpointId=$ENDPOINTID&method=repository&type=2" \
       -H "authorization: Bearer $TOKEN" \
       -H 'content-type: application/json' \
       --data @-

}

update_stack()
{
    [ -z $VERBOSE ] && echo "Update_Stack $1"
    STACK=$(list_stacks | jq --raw-output "select(.Name == \"$1\")")
    STACKID=$(echo $STACK | jq --raw-output ".Id")
    STACK_DEPLOYER=$(echo $STACK | jq --raw-output '.GitConfig.Authentication.Username')
    [ -z $VARIABLES_JSON ] && VARIABLES_JSON=$(echo $STACK | jq --raw-output '.Env')
    [ -z $TOKEN ] && login
    [ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location 'https://portainer.octubre.org.ar/api/endpoints' --header "Authorization: Bearer $TOKEN" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    [ -z $VERBOSE ] && echo "$ENDPOINTID"
    [ -z $VERBOSE ] && echo "$TOKEN"
    [ -z $VERBOSE ] && echo "$STACKID"
    [ -z $VERBOSE ] && echo "$STACK_DEPLOYER"
    DATA=$( echo "{
        \"prune\": false,
        \"RepositoryUsername\": \"$STACK_DEPLOYER\",
        \"PullImage\":true,
        \"RepositoryAuthentication\":true,
        \"Env\": $VARIABLES_JSON
    }" | jq -c '.' )
    [ -z $VERBOSE ] && echo $DATA
    echo $DATA |
     curl -i "https://portainer.octubre.org.ar/api/stacks/$STACKID/git/redeploy?endpointId=$ENDPOINTID" \
     -X 'PUT' \
     -H "authorization: Bearer $TOKEN" \
     -H 'content-type: application/json' \
     --data @-
}

delete_stack()
{
    [ -z $VERBOSE ] && echo "Delete_Stack $1"
    STACK=$(list_stacks | jq --raw-output "select(.Name == \"$1\")")
    STACKID=$(echo $STACK | jq --raw-output ".Id")
    [ -z $TOKEN ] && login
    #[ -z $ENDPOINTID ] && ENDPOINTID=$(curl -s --location 'https://portainer.octubre.org.ar/api/endpoints' --header "Authorization: Bearer $TOKEN" | jq ".[] | select(.Name == \"$HOST\") | .Id")
    [ -z $VERBOSE ] && echo "$ENDPOINTID"
    [ -z $VERBOSE ] && echo "$TOKEN"
    [ -z $VERBOSE ] && echo "$STACKID"
    [ -z $VERBOSE ] && echo $DATA
    curl -i "https://portainer.octubre.org.ar/api/stacks/$STACKID" \
    -X 'DELETE' \
    -H "authorization: Bearer $TOKEN" \
    -H 'content-type: application/json'
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

