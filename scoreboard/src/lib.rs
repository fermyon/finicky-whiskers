use anyhow::Result;
use http::Uri;
use rusty_ulid::Ulid;
use serde::{Deserialize, Serialize};
use spin_sdk::{
    http::{Request, Response},
    http_component,
    key_value::Store,
};
use std::collections::HashMap;
use std::str;

#[http_component]
fn scoreboard(req: Request) -> Result<Response> {
    let ulid = get_ulid(req.uri())?;

    let score = match get_scores(&ulid) {
        Ok(scores) => scores,
        Err(e) => {
            eprintln!("Error fetching scorecard: {}", e);
            // Return a blank scorecard.
            Scorecard::new(ulid)
        }
    };

    let msg = serde_json::to_string(&score)?;
    Ok(http::Response::builder()
        .status(200)
        .body(Some(msg.into()))?)
}

#[derive(Deserialize, Serialize)]
pub struct Scorecard {
    pub ulid: Ulid,
    pub beef: i32,
    pub fish: i32,
    pub chicken: i32,
    pub veg: i32,
    pub total: i32,
}

impl Scorecard {
    fn new(ulid: Ulid) -> Self {
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

fn get_ulid(url: &Uri) -> Result<Ulid> {
    let params = simple_query_parser(url.query().unwrap_or(""));
    match params.get("ulid") {
        Some(raw_ulid) => {
            let ulid = raw_ulid.parse()?;
            Ok(ulid)
        }
        None => anyhow::bail!("ULID is required in query parameters"),
    }
}

fn get_scores(ulid: &Ulid) -> Result<Scorecard> {
    let store = Store::open_default()?;

    let raw_scorecard = store
        .get(format!("fw-{}", ulid.to_string()))
        .map_err(|e| anyhow::anyhow!("Error fetching from key/value: {e}"))?;
    let score: Scorecard = serde_json::from_slice(raw_scorecard.as_slice())?;
    Ok(score)
}

fn simple_query_parser(q: &str) -> HashMap<String, String> {
    let mut dict = HashMap::new();
    q.split('&').for_each(|s| {
        if let Some((k, v)) = s.split_once('=') {
            dict.insert(k.to_string(), v.to_string());
        }
    });
    dict
}
