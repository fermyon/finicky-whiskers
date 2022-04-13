# Finicky Whiskers

A game that demonstrates wasm microservices. And the complex dietary whims of a cat called Slats.

### Development

To run Finicky Whiskers locally:

1. Run Spin (with [this Redis update](https://github.com/fermyon/spin/pull/328)) and export the Path
    ```
    cd spin
    make build
    ```
    
    Then export the PATH: `export PATH=$PWD/target/release:$PATH`
    
2. In the same shell session, move to the finicky-whiskers directory, and use `spin up`
    ```
    cd ../finicky-whiskers
    spin up --file spin.toml
    ```
    
    This will run the game at [http://127.0.0.1:3000](http://127.0.0.1:3000)


### Data Endpoint

Hit the `/session` endpoint: http://127.0.0.1:3000/session

This creates a data array for the game, which we can fetch and consume with the [`fetch()` JavaScript Interface](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch).