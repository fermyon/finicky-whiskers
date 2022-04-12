Not much here yet.

## To Build

Each microservice has its own `Makefile`. However, at this time only `session` needs to be built from source. The rest all have pre-built binaries in `components/`.

## To Run

Once `session` is built, you should be able to run with `spin up` in this directory.

To run `morsel_event`, you must run `spin up` in that directory to start the Redis listener.