Finicky Whiskers is comprised of a handful of microservices.

- [redirect](./redirect/README.md)
- [reset](./reset/README.md)
- [scoreboard](./scoreboard/README.md)
- [session](./session/README.md)
- [site](./site/README.md)
- [tally](./tally/README.md)

## Prerequisites

You'll need Spin [v0.4.1](https://github.com/fermyon/spin/releases/tag/v0.4.1)
to run the site locally.

You will also need `wasi-vfs` to build and run the Ruby component:
```
$ brew tap kateinoigakukun/wasi-vfs https://github.com/kateinoigakukun/wasi-vfs.git
$ brew install kateinoigakukun/wasi-vfs/wasi-vfs
```

## To Build

This will by default build all microservices per the `Makefile` in their directories:

```console
spin build
```

You may also build a particular microservice by navigating into its directory
and running `make build` or from the root of this repo via
`make build-<microservice>` e.g.:

```console
make build-session
```

## To Run

The following command will serve the Finicky Whiskers site locally:

```console
spin up --sqlite @highscore/migration.sql
```

This will run the game at [http://127.0.0.1:3000](http://127.0.0.1:3000)

## To Test

The following command will serve the site and then run the integration test
as seen [here](./tests/test-server.sh):

```console
make test-server
```

## Development Notes

For working on the game UI (styles, etc):


Recompiling Assets:

```console
cd site
npm i
npm run styles
```

To just run the UI locally (without the other services) use [Parcel](https://parceljs.org/features/development/) via `npm run dev` and then view the site at [localhost:1234](http://localhost:1234/)

