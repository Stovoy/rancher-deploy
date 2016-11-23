[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
# rancher-deploy.sh

Does a Rancher upgrade.

You will need to create an API access token and secret for Rancher.

If you wanted to deploy swaggy/awesome:3.0, you'd set `DOCKER_IMAGE=swaggy/awesome`, and `TAG=3.0`.

If your tag is unique each deploy, you should set `USE_TAG` to true. But if you always deploy the same tag (i.e. latest), you should set `use_tag` to false. `use_tag` just sets the rancher service name to include the tag, for example awesome-3.0 -> awesome-3.1. But if your tag is not unique, then a random number will be generated for you. Rancher enforces that the service has to have a new unique name on every deploy.

If you use in-place mode, then you don't need new unique names. Just set `USE_TAG` to false and `IN_PLACE` to true.

The rancher URL needs to be your full url including the project id. You can get the url on your api key page - it's the highlighted text next to "Endpoint". Make sure you create the api key in the environment you want to use. 
Note: Don't include http/s:// in the url - it's added through a flag (HTTPS).

## Necessary packages
* jq
* unzip

## Necessary variables
* ACCESS_KEY
* SECRET_KEY
* RANCHER_URL
* STACK_NAME
* SERVICE_NAME
* DOCKER_ORG
* DOCKER_IMAGE

## Optional variables
* HTTPS (default: true)
* TAG (default: latest)
* USE_TAG (default: true)
* IN_PLACE (default: true)
* START_FIRST (default: true)
* RANCHER_COMPOSE_TAR (default: https://releases.rancher.com/compose/v0.8.6/rancher-compose-linux-amd64-v0.8.6.tar.gz)
* CLEANUP (default: true)

## Example environment
```
ACCESS_KEY=$RANCHER_ACCESS_KEY
SECRET_KEY=$RANCHER_SECRET_KEY
RANCHER_URL=$RANCHER_URL
HTTPS=false
TAG=latest
STACK_NAME=my-stack
SERVICE_NAME=awesome
DOCKER_ORG=swaggy
DOCKER_IMAGE=awesome
USE_TAG=false
IN_PLACE=true
START_FIRST=true
```

## Running it
After your environmental variables are set, you can run it like this:

`curl https://raw.githubusercontent.com/swaggy/rancher-deploy/master/rancher-deploy.sh | bash`

## Example CircleCi deployment

```yaml
deployment:
  master:
    branch: master
    commands:
      - curl https://raw.githubusercontent.com/swaggy/rancher-deploy/master/rancher-deploy.sh | bash:
          environment:
            ACCESS_KEY: $RANCHER_ACCESS_KEY
            SECRET_KEY: $RANCHER_SECRET_KEY
            RANCHER_URL: $RANCHER_URL
            STACK_NAME: $CIRCLE_PROJECT_REPONAME
            SERVICE_NAME: $CIRCLE_PROJECT_REPONAME
            DOCKER_IMAGE: $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$DOCKER_IMAGE
            TAG: $DOCKER_TAG
```
