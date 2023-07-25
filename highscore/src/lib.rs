use core::panic;

use anyhow::{Error, Result};
use http::Method;
use rusty_ulid::Ulid;
use serde::{Deserialize, Serialize};
use spin_sdk::{
    http::{Request, Response},
    http_component, sqlite::{Row, ValueParam},
};

#[http_component]
fn highscore(req: Request) -> Result<Response> {
    let res_body: String = match *req.method() {
        Method::GET => {
            serde_json::to_string_pretty(&get_highscore().unwrap()).unwrap()
        }
        Method::POST => check_highscore(req).unwrap_or_else(|_| "".to_string()),
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

fn check_highscore(req: Request) -> Result<String> {
    println!("Incoming body: {:?}", req.body());

    // Parsing incoming request to HighScore
    let incoming_score: HighScore = match req.body() {
        Some(b) => serde_json::from_slice(b)?,
        None => panic!("Failed to parse the incoming request"),
    };

    // Inserting the highscore into the database
    replace_highscore(&incoming_score)?;

    // Fetching the highscores from store (JsonBin)
    let highscores = match get_highscore() {
        Ok(highscores) => highscores,
        Err(e) => panic!("Tried to get high score: {}", Error::msg(e.to_string())),
    };

    // Check if the incoming score made the high score list
    let incoming_score_pos = highscores
        .iter()
        .position(|s| s.ulid.unwrap() == incoming_score.ulid.unwrap());

    let rank = match incoming_score_pos {
        Some(r) => {
            println!("It is a high score at {}", r + 1);
            r + 1
        },
        None => {
            println!("It is not a high score");
            delete_highscore(incoming_score.ulid.unwrap())?;
            0
        },
    };

    // Setting up response
    let response = HighScoreResult {
        is_high_score: rank > 0,
        rank,
        high_score_table: highscores,
    };

    let res_body = serde_json::to_string_pretty(&response)?;

    Ok(res_body)
}

fn get_highscore() -> Result<Vec<HighScore>> {
    let conn = spin_sdk::sqlite::Connection::open_default()?;
    let query = "SELECT ulid, score, username FROM highscore ORDER BY score DESC LIMIT 10";
    let result = conn.execute(query, &[])?;
    let highscores = result.rows().map(HighScore::from).collect::<Vec<_>>();
    Ok(highscores)
}

fn replace_highscore(highscore: &HighScore) -> Result<()> {
    let conn = spin_sdk::sqlite::Connection::open_default()?;
    let query = "REPLACE INTO highscore (ulid, score, username) VALUES (?, ?, ?)";

    let ulid = highscore.ulid.expect("ulid is required").to_string();
    let params = &[
        ValueParam::Text(&ulid), 
        ValueParam::Integer(highscore.score as i64), 
        ValueParam::Text(&highscore.username)
    ];
    conn.execute(query, params)?;
    Ok(())
}

fn delete_highscore(ulid: Ulid) -> Result<()> {
    let conn = spin_sdk::sqlite::Connection::open_default()?;
    let query = "DELETE FROM highscore WHERE ulid = ?";
    let ulid = ulid.to_string();
    let params = &[ValueParam::Text(&ulid)];
    conn.execute(query, params)?;
    Ok(())
}

#[derive(Deserialize, Serialize)]
struct HighScore {
    score: i32,
    username: String,
    ulid: Option<Ulid>,
}

impl From<Row<'_>> for HighScore {
    fn from(row: Row<'_>) -> Self {
        let uscore = row.get::<u32>("score")
            .expect("column 'score' not found in row");
        let username = row.get::<&str>("username")
            .expect("column 'username' not found in row");
        let ulid = row.get::<&str>("ulid")
            .expect("column 'ulid' not found in row");
        HighScore {
            score: i32::try_from(uscore).expect("failed to convert score to an i32"),
            username: username.to_string(),
            ulid: ulid.parse::<Ulid>().ok(),
        }
    }
}

#[derive(Deserialize, Serialize)]
struct HighScoreResult {
    is_high_score: bool,
    rank: usize,
    high_score_table: Vec<HighScore>,
}
