# Deployments

The [Finicky Whiskers](https://finickywhiskers.com) website is deployed via the [deploy.yaml](../.github/workflows/deploy.yml) GitHub workflow.

## Auto Deploys

The production version of the website is deployed whenever commits are pushed to the `main` branch.

## www redirect app

The [finicky-whiskers-www-redirect app](./finicky-whiskers-www-redirect/) is used to redirect all `www.finickywhiskers.com` requests to the canonical `finickywhiskers.com` URL. It is deployed via the [deploy.yaml](../.github/workflows/deploy.yml) GitHub workflow as well.
