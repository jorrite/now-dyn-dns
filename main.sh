#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $1

IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
RESULT=$(curl -s "https://api.zeit.co/v2/domains/$DOMAIN/records" \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r --arg IP "$IP" \
  --arg NAME "$SUBDOMAIN" \
  '.[][] | select(.name==$NAME and .value==$IP) | .id')

if [ -z "$RESULT" ]
then
    #check if there is another record and delete it later on...
    ID=$(curl -s "https://api.zeit.co/v2/domains/$DOMAIN/records" \
        -H "Authorization: Bearer $TOKEN" | \
        jq -r --arg IP "$IP" \
        --arg NAME "$SUBDOMAIN" \
        '.[][] | select(.name==$NAME) | .id')

    curl -X POST "https://api.zeit.co/v2/domains/$DOMAIN/records" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
        "name": "'$SUBDOMAIN'",
        "type": "A",
        "value": "'$IP'"
        }'
    
    #deleting earlier found ID, if any
    if [[ ! -z "$ID" ]]
    then
        curl -X DELETE "https://api.zeit.co/v2/domains/$DOMAIN/records/$ID" \
            -H "Authorization: Bearer $TOKEN"
    fi
fi