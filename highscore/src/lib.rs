use core::panic;

use anyhow::{anyhow, Error, Result};
use http::Method;
use rusty_ulid::Ulid;
use serde::{Deserialize, Serialize};
use spin_sdk::{
    http::{Request, Response},
    http_component,
    key_value::Store,
};

#[http_component]
fn highscore(req: Request) -> Result<Response> {
    let store = Store::open_default()?;
    let res_body: String = match *req.method() {
        Method::GET => serde_json::to_string_pretty(&get_highscore(&store).unwrap()).unwrap(),
        Method::POST => check_highscore(req, &store).unwrap_or_else(|_| "".to_string()),
        _ => "".to_string(),
    };

    let mut status = 200;

    if res_body.is_empty() {
        status = 405;
    }

    Ok(http::Response::builder()
        .status(status)
        .body(Some(res_body.into()))?)
}

fn check_highscore(req: Request, store: &Store) -> Result<String> {
    println!("Incoming body: {:?}", req.body());

    // Parsing incoming request to HighScore
    let incoming_score: HighScore = match req.body() {
        Some(b) => serde_json::from_slice(b)?,
        None => panic!("Failed to parse the incoming request"),
    };

    // Fetching the highscores from store (JsonBin)
    let mut high_score_table = match get_highscore(&store) {
        Ok(high_score_table) => high_score_table,
        Err(e) => panic!("Tried to get high score: {}", Error::msg(e.to_string())),
    };

    // Sorting the highscore in descending order
    // high_score_table.sort_by_key(|k| -(k.score));

    let mut is_high_score = false;
    let mut rank = 0;

    if high_score_table.len() < 10 {
        is_high_score = true;
    }
    // Check if the incoming score is larger than the lowest score,
    else if incoming_score.score > high_score_table[9].score {
        is_high_score = true;
        // removing the last score
        if !incoming_score.username.is_empty() {
            high_score_table.remove(9);
        }
    } else {
        println!("It's not a high score");
    }
    if is_high_score {
        // adding it to the vector
        high_score_table.push(HighScore {
            score: incoming_score.score,
            username: incoming_score.username.clone(),
            ulid: incoming_score.ulid,
        });
        // sorting (descending)
        high_score_table.sort_by_key(|k| -(k.score));

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
            store
                .set(
                    "fw-highscore-list",
                    &serde_json::to_vec_pretty(&high_score_table)?,
                )
                .map_err(|_| anyhow!("Error storing in key/value"))?;
        }
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

fn get_highscore(store: &Store) -> Result<Vec<HighScore>> {
    let payload = store.get("fw-highscore-list");

    let highscore_list: Vec<HighScore> = match payload {
        Ok(value) => {
            let a = serde_json::from_slice(&value);
            match a {
                Ok(val) => val,
                _ => Vec::new(),
            }
        }
        _ => Vec::new(),
    };

    Ok(highscore_list)
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
