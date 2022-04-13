use anyhow::Result;
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use spin_sdk::{redis, redis_component};
use tally::Tally;

mod tally;

const REDIS_ADDRESS_ENV: &str = "REDIS_ADDRESS";

#[redis_component]
fn on_message(msg: Bytes) -> anyhow::Result<()> {
    let address = std::env::var(REDIS_ADDRESS_ENV)?;

    let tally_mon: Tally = serde_json::from_slice(&msg)?;

    if !tally_mon.correct {
        return Ok(());
    }

    let id: rusty_ulid::Ulid = tally_mon.ulid.parse()?;

    let mut scorecard = match redis::get(&address, &id.to_string()) {
        Err(_) => Scorecard::new(id),
        Ok(data) => serde_json::from_slice(&data).unwrap_or_else(|_| Scorecard::new(id)),
    };

    match tally_mon.food.as_str() {
        "chicken" => scorecard.chicken += 1,
        "fish" => scorecard.fish += 1,
        "beef" => scorecard.beef += 1,
        "veg" => scorecard.veg += 1,
        _ => {}
    };

    scorecard.total += 1;

    if let Ok(talled_mon) = serde_json::to_vec(&scorecard) {
        redis::set(&address, &id.to_string(), &talled_mon)
            .map_err(|_| anyhow::anyhow!("Error saving to Redis"))?;
    }

    Ok(())
}

#[derive(Deserialize, Serialize)]
struct Scorecard {
    pub ulid: rusty_ulid::Ulid,
    pub beef: i32,
    pub fish: i32,
    pub chicken: i32,
    pub veg: i32,
    pub total: i32,
}

impl Scorecard {
    fn new(ulid: rusty_ulid::Ulid) -> Self {
        Scorecard {
            ulid,
            beef: 0,
            fish: 0,
            chicken: 0,
            veg: 0,
            total: 0,
        }
    }
}
