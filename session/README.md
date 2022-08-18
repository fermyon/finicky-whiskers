Responsible for creating a finicky whiskers session.

It generates a ULID token and sends it back to the browser, along with an initial food.

The session data is returned as json.

- ulid: The ULID for the session
- menu: The food selection and offset
  - demand: The type of food for a duration
  - offset: The milliseconds that the demand will last until

```json

{
  "id": "01G050RK3JV7PHS7RKDPBHC29Q",
  "menu": [
    {
      "offset": 0,
      "demand": "meat"
    },
    {
      "offset": 3803,
      "demand": "fish"
    },
    {
      "offset": 9142,
      "demand": "meat"
    }
  ]
}
```

## Building

This module depends on [wasi-vfs](https://github.com/kateinoigakukun/wasi-vfs) to package Ruby into a single file.

Run `make ruby .gem` in this directory to build.

To serve, use the `spin.toml` file in the parent directory.
