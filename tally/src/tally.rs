use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize, Debug)]
pub struct Tally {
    pub ulid: String,
    pub food: String,
    pub correct: bool,
}
