-- taking a shortcut here and dropping the highscore table on every migration
DROP TABLE IF EXISTS highscore;
CREATE TABLE highscore (
    ulid TEXT(26) PRIMARY KEY,
    score INTEGER NOT NULL,
    username TEXT(3)
);