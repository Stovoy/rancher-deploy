[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
## rancher-deploy.sh

Does a Rancher upgrade.

You will need to create an API access token and secret for Rancher.

The rancher URL needs to be your full url including project id. You will get the url on your api key page. Make sure you are using the environment you want to use. Do not include http/s in the url. There is an option for https.

If I wanted to deploy swaggy/awesome:3.0 I would use `docker_org: swaggy`, `docker_image: awesome`, and `tag: 3.0`.

If your tag is unique each deploy, you should set `use_tag` to true. But if you always deploy the same tag (i.e. latest), you should set `use_tag` to false. `use_tag` just sets the rancher service name to include the tag, for example awesome-3.0 -> awesome-3.1. But if your tag is not unique, then a random number will be generated for you. Rancher enforces that the service has to have a new unique name on every deploy.

If you use inplace mode, then you don't need new unique names. Just set `use_tag` to false and `inplace` to true.

Set up your environmental variables for your use case:
```
access_key: $RANCHER_ACCESS_KEY
secret_key: $RANCHER_SECRET_KEY
rancher_url: $RANCHER_URL
https: false
tag: latest
stack_name: my-stack
service_name: awesome
docker_org: swaggy
docker_image: awesome
use_tag: false
inplace: true
start_first: true
```
Running it is simple.
`curl https://github.com/swaggy/rancher-deploy/blob/master/run.sh | sh`
