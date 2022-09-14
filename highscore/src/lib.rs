use core::panic;

use anyhow::{Error, Result};
use http::{Method, StatusCode};
use rusty_ulid::Ulid;
use serde::{Deserialize, Serialize};
use spin_sdk::{
    config,
    http::{Request, Response},
    http_component,
};

#[http_component]
fn highscore(req: Request) -> Result<Response> {
    let config = Config {
        jsonbin_endpoint: config::get("jsonbin_endpoint")
            .expect("Failed to acquire jsonbin_endpoint from spin.toml"),
        master_key: config::get("master_key").expect("Failed to acquire master_key from spin.toml"),
        access_key: config::get("access_key").expect("Failed to acquire access_key from spin.toml"),
    };

    println!("Using JsonBin: {:?}", &config.jsonbin_endpoint);

    let res_body: String = match *req.method() {
        Method::GET => serde_json::to_string_pretty(&get_highscore(&config).unwrap()).unwrap(),
        Method::POST => check_highscore(req, config).unwrap_or_else(|_| "".to_string()),
        _ => "".to_string()
    };

    let mut status = 200;

    if res_body.is_empty() {
        status = 405;
    }

    Ok(http::Response::builder()
        .status(status)
        .body(Some(res_body.into()))?)
}

fn check_highscore(req: Request, config: Config) -> Result<String> {
    println!("Incoming body: {:?}", req.body());

    // Parsing incoming request to HighScore
    let incoming_score: HighScore = match req.body() {
        Some(b) => serde_json::from_slice(b)?,
        None => panic!("Failed to parse the incoming request"),
    };

    // Fetching the highscores from store (JsonBin)
    let mut high_score_table = match get_highscore(&config) {
        Ok(high_score_table) => high_score_table,
        Err(e) => panic!("Tried to get high score: {}", Error::msg(e.to_string())),
    };

    // Sorting the highscore in descending order
    // high_score_table.sort_by_key(|k| -(k.score));

    let mut is_high_score = false;
    let mut rank = 0;

    // Check if the incoming score is larger than the lowest score,
    if incoming_score.score > high_score_table[9].score {
        is_high_score = true;

        // adding it to the vector
        high_score_table.push(HighScore {
            score: incoming_score.score,
            username: incoming_score.username.clone(),
            ulid: incoming_score.ulid,
        });
        // sorting (descending)
        high_score_table.sort_by_key(|k| -(k.score));
        // removing the 11th score
        high_score_table.remove(10);

        /*
        You're welcome to implement a binary search function
        to get the high score in the right place and replace the above
        */

        // Getting the rank of the score
        match high_score_table
            .iter()
            .position(|p| p.ulid == incoming_score.ulid)
        {
            Some(r) => rank = r + 1,
            None => todo!(),
        };

        println!("It's a high score at {}", rank);

        // If it has a username, let's store the result
        if !incoming_score.username.is_empty() {
            let body = serde_json::to_string_pretty(&high_score_table)?;

            let _res = spin_sdk::http::send(
                http::Request::builder()
                    .method("PUT")
                    .uri(config.jsonbin_endpoint)
                    .header("X-Master-Key", config.master_key)
                    .header("X-Bin-Versioning", "false")
                    .header("content-type", "application/json")
                    .body(Some(body.into()))?,
            );
        }
    } else {
        println!("It's not a high score");
    }

    // Setting up response
    let response = HighScoreResult {
        is_high_score,
        rank,
        high_score_table,
    };

    let res_body = serde_json::to_string_pretty(&response)?;

    Ok(res_body)
}

fn get_highscore(config: &Config) -> Result<Vec<HighScore>> {

    let _res = spin_sdk::http::send(
        http::Request::builder()
            .method("GET")
            .uri(&config.jsonbin_endpoint)
            .header(
                "X-Master-Key",
                &config.master_key,
            )
            .header(
                "X-Access-Key",
                &config.access_key,
            )
            .header(
                "X-Bin-Meta",
                "false",
            )
            .body(None)?,
    );

    let _body_bytes = match &_res {
        Ok(r) => {
            match r.status() {
                StatusCode::OK => {
                    println!("{:?}", r.body());
                    r.body()
                },
                _ => panic!("Error received from JsonBin. {:?} {:?}", r.status(), r.body()),
            }
            
        }
        Err(e) => panic!("Error getting body. {:?}", e.to_string()),
    };

    let _high_scores = match _body_bytes {
        Some(b) => serde_json::from_slice(b)?,
        None => panic!("Didn't get any data from jsonbin.io"),
    };

    Ok(_high_scores)
}

#[derive(Deserialize, Serialize)]
struct HighScore {
    score: i32,
    username: String,
    ulid: Option<Ulid>,
}

#[derive(Deserialize, Serialize)]
struct HighScoreResult {
    is_high_score: bool,
    rank: usize,
    high_score_table: Vec<HighScore>,
}

struct Config {
    jsonbin_endpoint: String,
    master_key: String,
    access_key: String,
}
