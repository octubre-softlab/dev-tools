#!/bin/bash
#set -xe

while getopts "a:h:e:t:u:p:b:d:k:" option; do
    case $option in
        a)
            APP=${OPTARG}
            ;;
        h)
            HOST=${OPTARG}
            ;;
        e)
            ENVIRONMENT=${OPTARG}
            ;;
        t)
            TENANT=${OPTARG}
            ;;
        u)
            USER=${OPTARG}
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        k)
            API_KEY=${OPTARG}
            ;;
        b)
            BRANCH=${OPTARG}
            ;;
        d)
            DOMAIN=${OPTARG}
            ;;
    esac
done

REVIEW_VARS=$(echo "
[
  {
    \"name\":\"TENANT\",
    \"value\":\"$TENANT\",
    \"nivel\":7
  },
    {
    \"name\":\"IMAGE_TAG\",
    \"value\":\"$BRANCH-$TENANT\",
    \"nivel\":7
  },
    {
    \"name\":\"DOMAIN\",
    \"value\":\"$DOMAIN\",
    \"nivel\":7
  }
]" | jq .)

ENV_VARS=$(echo $REVIEW_VARS | Get-EnvFile -c appcs-sharedconf2-prd-ue -a $APP -t $TENANT -e $ENVIRONMENT -h $HOST -V) 

echo $ENV_VARS | deploy-portainer -k $API_KEY -u $USER -p $PASSWORD -h $HOST -c review-$BRANCH -f compose_apps/webapi/review-linux/docker-compose.Review.yml -V
