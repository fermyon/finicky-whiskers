Generate the scoreboard at the end of the game

## Building Scoreboard

The `components/scoreboard.wasm` file should be the latest. However, if you need to build from source, use `make build`. You will need to have Rust and Spin to build.

At this time, you may need to manually edit the Cargo.toml to point to the correct Spin path.

## Using the Scorecard API endpoint

The scorecard API expects the following query parameters:

- `ulid`: The ULID for the game session

Example with Curl (using `rusty_ulid` to generate a ULID):

```console
$ curl localhost:3000/score\?ulid=$(rusty_ulid)
{"id":"01G0DKQK8FZ6ZFVP0DMR9RNH47","beef":5,"fish":7,"chicken":33,"veg":10,"total":55}
```

This will return a simple JSON file:

```json
{
    "id":"01G0DKQK8FZ6ZFVP0DMR9RNH47",
    "beef":5,
    "fish":7,
    "chicken":33,
    "veg":10,
    "total":55
}
```
