use anyhow::Result;
use http::Uri;
use rusty_ulid::Ulid;
use spin_sdk::{
    http::{Request, Response},
    http_component,};
use serde::Serialize;
use std::collections::HashMap;


#[http_component]
fn scoreboard(req: Request) -> Result<Response> {

    let ulid = get_ulid(req.uri())?;

    let score = Scorecard{
        id: ulid,
        meat: 5,
        fish: 7,
        chicken: 33,
        veg: 10,
        total: 55,
    };

    let msg = serde_json::to_string(&score)?;

    Ok(http::Response::builder()
                .status(200)
                .body(Some(msg.into()))?)

}

#[derive(Serialize)]
pub struct Scorecard {
    pub id: Ulid,
    pub meat: i32,
    pub fish: i32,
    pub chicken: i32,
    pub veg: i32,
    pub total: i32,
}

fn get_ulid(url: &Uri) -> Result<Ulid> {
    let params = simple_query_parser(url.query().unwrap_or(""));
    match params.get("ulid") {
        Some(raw_ulid) => {
            let ulid = raw_ulid.parse()?;
            Ok(ulid)
        },
        None => anyhow::bail!("ULID is required in query parameters")
    }
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