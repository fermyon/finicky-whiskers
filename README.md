Finicky Whiskers is comprised of a handful of microservices. Click on each item
below to see more details around a particular microservice.

- [redirect](./redirect/README.md)
- [scoreboard](./scoreboard/README.md)
- [session](./session/README.md)
- [site](./site/README.md)
- [tally](./tally/README.md)

## Prerequisites

You'll need Spin [v0.4.0](https://github.com/fermyon/spin/releases/tag/v0.4.0)
to run the site locally.

You will also need `wasi-vfs` in order to build and run the Ruby part:
```
$ brew tap kateinoigakukun/wasi-vfs https://github.com/kateinoigakukun/wasi-vfs.git
$ brew install kateinoigakukun/wasi-vfs/wasi-vfs
```

## To Build

This will by default build all microservices per the `Makefile` in their directories:

```console
make build
```

You may also build a particular microservice by navigating into its directory
and running `make build` or from the root of this repo via
`make build-<microservice>` e.g.:

```console
make build-session
```

## To Run

Finicky Whiskers depends on a Redis instance to run. The default connection
string is `redis://localhost:6379`.

If you have Docker installed, you can start a redis container like so:

```console
make start-redis
```

The following command will serve the Finicky Whiskers site locally:

```console
make serve
```

This will run the game at [http://127.0.0.1:3000](http://127.0.0.1:3000)

When finished, the following command will stop the redis container:

```console
make stop-redis
```

## To Test

The following command will serve the site and then run the integration test
as seen [here](./tests/test-server.sh):

```console
make test-server
```
