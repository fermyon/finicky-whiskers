use crate::tally::Tally;
use anyhow::Result;
use chrono::{Duration, Utc};
use http::Uri;
use rusty_ulid::Ulid;
use spin_sdk::{
    http::{Request, Response},
    http_component,
};
use std::collections::HashMap;

mod tally;

const GAME_DURATION_SECONDS: i64 = 30;

/// A simple Spin HTTP component.
#[http_component]
fn tally_point(req: Request) -> Result<Response> {
    // This gets info out of query params
    match parse_query_params(req.uri()) {
        Ok(tally) => {
            // Should store something in Redis.

            // Send a response
            let msg = format!("ULID: {:?}", tally.ulid);
            Ok(http::Response::builder()
                .status(200)
                .body(Some(msg.into()))?)
        }
        Err(e) => Err(e),
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

/*
 * TODO: This is in case we decode to post a JSON body instead of using query params.
 * If not, we can totally remove it.


fn parse_post_body(req: Request) -> Result<Tally> {
    // Get body instead of using query params
    //
    // Currently this will work with
    // curl -XPOST http://localhost:3000/tally --data '{"ulid": "1234", "food": "veg"}'
    match req.body() {
        // Don't you want
        Some(body) => { // to love
            let body: tally::Tally = serde_json::from_slice(&body.to_vec())?;
            Ok(body)
        },
        None => anyhow::bail!("No body supplied")
    }
}
*/

fn parse_query_params(url: &Uri) -> Result<Tally> {
    // Get the necessary stuff out of the request:
    let params = simple_query_parser(url.query().unwrap_or(""));
    let ulid = params.get("ulid");
    let food = params.get("food");
    let correct = params.get("correct");

    if ulid.is_none() || food.is_none() || correct.is_none() {
        anyhow::bail!("ULID, food, and correct are required: {}", url.to_string());
    }

    validate_ulid(ulid.unwrap().as_str())?;

    Ok(Tally {
        ulid: ulid.unwrap().clone(),
        food: food.unwrap().clone(),
        correct: correct.unwrap().to_lowercase().starts_with("t"),
    })
}

fn validate_ulid(ulid: &str) -> anyhow::Result<Ulid> {
    let id: Ulid = ulid.parse()?;

    // Check expiration
    let now = Utc::now();
    if id.datetime() + Duration::seconds(GAME_DURATION_SECONDS) < now {
        anyhow::bail!("Session is expired")
    }

    Ok(id)
}

#[cfg(test)]
mod test {
    use super::*;
    use rusty_ulid::Ulid;
    #[test]
    fn test_validate_ulid() {
        {
            let ulid = "01CB2EMMMV";
            validate_ulid(ulid).expect_err("ULID is malformed and should have failed");
        }
        {
            // This ULID is from '2018-04-14 16:08:33.691 UTC'
            let ulid = "01CB2EMMMV8P51SCR9ZH8K64CX";
            validate_ulid(ulid).expect_err("ULID is old and should have failed");
        }
        {
            let ulid = Ulid::generate();
            validate_ulid(&ulid.to_string())
                .expect("This ULID is mere milliseconds old and should pass");
        }
    }

    #[test]
    fn test_parse_query_params() {
        {
            let valid_url = format!(
                "http://example.com/foo?ulid={}&food=fish&correct=true",
                Ulid::generate()
            );
            let url: http::Uri = valid_url.parse().expect("URL is valid and will parse");
            let tally = parse_query_params(&url).expect("Query params should parse");
            assert_eq!("fish", tally.food);
        }
        {
            let invalid_url = "http://example.com/foo?food=fish&correct=true";
            let url: http::Uri = invalid_url.parse().expect("URL is valid and will parse");
            parse_query_params(&url).expect_err("Ulid is missing so parse should fail");
        }
        
    }
}
