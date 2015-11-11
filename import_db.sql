DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  user_id INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER,
  user_id INTEGER,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES question(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  question_id INTEGER,


  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (question_id) REFERENCES question(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Kareem', 'Ascha'),
  ('Tevy', 'JacobsGomes');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('SQL Question', 'What is SQL?', (
    SELECT
      id
    FROM
      users
    WHERE fname = 'Kareem'
  )),
  ('Tevys First Question', 'Can we subquery without a comma?', 2);

INSERT INTO
  question_follows (question_id, user_id)
VALUES
  (2,1),
  (1,2);

INSERT INTO
  replies (question_id, parent_reply_id, user_id, body)

VALUES
  (1, null, 2, "SQL is a language to talk to databases"),
  (1, 1, 1, "Cool"),
  (2, null, 1, "Yes");

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (2, 1),
  (1, 2);
