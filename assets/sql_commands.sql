-- Create tables --

CREATE TABLE users(
	user_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    auth_id VARCHAR(20) NOT NULL,
    credits BIGINT NOT NULL
);

CREATE TABLE items(
	item_id VARCHAR(128) NOT NULL PRIMARY KEY
);

CREATE TABLE inventory(
	user_id INT NOT NULL,
	item_id VARCHAR(128) NOT NULL PRIMARY KEY,
    equipped BOOL NOT NULL
);

-- Validate Databaase

-- check if database has been created
SELECT count(*) AS count
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'yamp';

-- verify tables one by one
SELECT * FROM users;
SELECT * FROM items;
SELECT * FROM inventory;

-- drop tables
DROP TABLE users;
DROP TABLE items;
DROP TABLE inventory;


-- User Entries

-- check if client has entry
SELECT * FROM users WHERE auth_id = '';

-- create client entry
INSERT INTO users (auth_id, credits) VALUES ('', );


-- Saving Clients

-- save credits
UPDATE users SET credits =  WHERE user_id = ;


-- Utility

SELECT * FROM users WHERE auth_id = 'STEAM_0:1:197188411';