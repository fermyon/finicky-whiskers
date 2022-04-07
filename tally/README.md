Responsible for sending an individual event to the Redis queue.

This expects a query string with the follow query params:

- ulid: The ULID for the session
- food: The name of the food
- correct: The string value `t` (or `true`) for correct. 

It then transforms this data into the following JSON data that is sent to Redis:

```json
{
    "ulid": "ULID",
    "food": "food name",
    "correct": true
}
```

## Building

Run `make build` in this directory to build.

> NOTE: At this time, you will need to edit `Cargo.toml` to point the Spin Rust SDK to the PR with the Redis Outbound implementation.

To serve, use the `spin.toml` file in the parent directory.

You must set the following environment variables either in `spin.toml` or on the CLI:

- `REDIS_ADDRESS`: The Redis URL, e.g. `redis://127.0.0.1:6379`
- `REDIS_CHANNEL`: The Redis channel name, e.g. `fw-tally`

## Manual Testing

If you `cargo install rusty_ulid`, then you can use this curl command to manually test:

```
curl localhost:3000/tally\?ulid=$(rusty_ulid)\&correct=TRUE\&food=fish
```