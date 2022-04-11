use anyhow::Result;
use bytes::Bytes;
use spin_sdk::redis_component;
use std::str::from_utf8;

#[redis_component]
fn on_message(msg: Bytes) -> anyhow::Result<()> {
    eprintln!("Received: {}", from_utf8(&msg)?);
    Ok(())
}