#!/bin/bash -e

# Needs `unzip`, `jq` packages.
if ! which unzip > /dev/null; then
    echo "rancher-deploy.sh needs unzip." 2>&1
    exit 1
fi

if ! which jq > /dev/null; then
    echo "rancher-deploy.sh needs jq." 2>&1
    exit 1
fi

# Check necessary variables.
declare -a WANTED_VARS=(
    "ACCESS_KEY"
    "SECRET_KEY"
    "RANCHER_URL"
    "STACK_NAME"
    "SERVICE_NAME"
    "DOCKER_IMAGE")

missing=false
for VAR in "${WANTED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "Missing $VAR."
        missing=true
    fi
done
if [[ $missing == true ]]; then
    exit 1
fi

# Parse optional variables:
# HTTPS (default: true)
# TAG (default: latest)
# USE_TAG (default: true)
# IN_PLACE (default: true)
# START_FIRST (default: true)
# RANCHER_COMPOSE_TAR (default: https://releases.rancher.com/compose/v0.8.6/rancher-compose-linux-amd64-v0.8.6.tar.gz)
# CLEANUP (default: true)

if [[ -z "$HTTPS" || "$HTTPS" == true ]]; then
    PROTOCOL=https
elif [[ "$HTTPS" == false ]]; then
    PROTOCOL=http
else
    echo "Invalid value for HTTPS: $HTTPS" 2>&1
    exit 1
fi

if [[ -z "$TAG" ]]; then
    TAG=latest
else
    TAG="$TAG"
fi

if [[ -z "$USE_TAG" || "$USE_TAG" == true ]]; then
    SUFFIX="$TAG"
elif [[ "$USE_TAG" == false ]]; then
    SUFFIX=$RANDOM
else
    echo "Invalid value for USE_TAG: $USE_TAG" 2>&1
    exit 1
fi

if [[ -z "$IN_PLACE" || "$IN_PLACE" == true ]]; then
    IN_PLACE=true
elif [[ "$IN_PLACE" != false ]]; then
    echo "Invalid value for IN_PLACE: $IN_PLACE" 2>&1
    exit 1
fi

if [[ -z "$START_FIRST" || "$START_FIRST" == true ]]; then
    START_FIRST=true
elif [[ "$START_FIRST" != false ]]; then
    echo "Invalid value for START_FIRST: $START_FIRST" 2>&1
    exit 1
fi

RANCHER_COMPOSE_TAR=${RANCHER_COMPOSE_TAR:-'https://releases.rancher.com/compose/v0.8.6/rancher-compose-linux-amd64-v0.8.6.tar.gz'}

if [[ -z "$CLEANUP" || "$CLEANUP" == true ]]; then
    CLEANUP=true
elif [[ "$CLEANUP" != false ]]; then
    echo "Invalid value for CLEANUP: $CLEANUP" 2>&1
    exit 1
fi

echo "Getting rancher compose executable."

# Strip directory to put rancher-compose directly in current directory.
curl "$RANCHER_COMPOSE_TAR" | tar xvz --strip-components=2
if [[ "$CLEANUP" == true ]]; then
    trap 'rm -f docker-compose' ERR EXIT
fi

ENV_ID=$(curl -s "$PROTOCOL://$ACCESS_KEY:$SECRET_KEY@$RANCHER_URL/environments?name=$STACK_NAME" | jq '.data[0].id' | sed s/\"//g)

wget -qO file.zip "$PROTOCOL://$ACCESS_KEY:$SECRET_KEY@$RANCHER_URL/environments/$ENV_ID/composeconfig"
if [[ "$CLEANUP" == true ]]; then
    trap 'rm -f file.zip' ERR EXIT
fi
unzip -o file.zip
if [[ "$CLEANUP" == true ]]; then
    trap 'rm -f docker-compose.yml rancher-compose.yml' ERR EXIT
fi

if [[ "$IN_PLACE" != true ]]; then
    OLD_SERVICE_NAME=$(sed -n "s/^\($SERVICE_NAME[^:]*\):[\r\n]$/\1/p" docker-compose.yml)
fi


if [[ "$IN_PLACE" != true ]]; then
    # Update docker-compose.yml to include new service name
    sed -i "s/^$OLD_SERVICE_NAME:/$OLD_SERVICE_NAME:\r\n$SERVICE_NAME-$SUFFIX:/g" docker-compose.yml
    sed -i "s/^$OLD_SERVICE_NAME:/$OLD_SERVICE_NAME:\r\n$SERVICE_NAME-$SUFFIX:/g" rancher-compose.yml
fi

# Update image in docker-compose.yml.
ESCAPED_DOCKER_IMAGE=$(echo "$DOCKER_IMAGE" | sed 's/\//\\\//g')  # Escape backslashes.
sed -i "s/^\(\s *image: $ESCAPED_DOCKER_IMAGE\).*$/\1:$TAG/g" docker-compose.yml

if [[ "$START_FIRST" == true ]]; then
    # Add start first directive to rancher-compose.yml.
    sed -i "s/\(^[a-zA-Z].*:\)/\1\r\n  upgrade_strategy:\r\n    start_first: true/g" rancher-compose.yml
fi
if [[ "$IN_PLACE" == true ]]; then
    echo "Starting upgrade..."
    ./rancher-compose --url "$PROTOCOL://$RANCHER_URL" --access-key "$ACCESS_KEY" --secret-key "$SECRET_KEY" --project-name "$STACK_NAME" up -d --upgrade --pull --interval 30000 --batch-size 1 "$SERVICE_NAME"
    echo "Done."
    if [[ "$START_FIRST" == false ]]; then
        # Have to wait before confirming because the pull and launch will happen asyncronously.
        echo "Waiting 60 seconds to confirm upgrade..."
        sleep 60
    fi
    echo "Confirming upgrade..."
    ./rancher-compose --url "$PROTOCOL://$RANCHER_URL" --access-key "$ACCESS_KEY" --secret-key "$SECRET_KEY" --project-name "$STACK_NAME" up -d --upgrade --confirm-upgrade "$SERVICE_NAME"
    echo "Done."
else
    ./rancher-compose --url "$PROTOCOL://$RANCHER_URL" --access-key "$ACCESS_KEY" --secret-key "$SECRET_KEY" --project-name "$STACK_NAME" upgrade "$OLD_SERVICE_NAME" "$SERVICE_NAME-$SUFFIX" --pull --update-links -c --interval 30000 --batch-size 1
fi
