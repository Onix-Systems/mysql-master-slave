CREATE TABLE IF NOT EXISTS `tbl_users` (
    id INT NOT NULL AUTO_INCREMENT,
    login VARCHAR(50) NOT NULL,
    pass varchar(50) NOT NULL,
    comment VARCHAR(100) NOT NULL DEFAULT "",

    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS `tbl_table1` (
    id INT NOT NULL AUTO_INCREMENT,
    comment VARCHAR(100) NOT NULL DEFAULT "",

    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS `tbl_table2` (
    id INT NOT NULL AUTO_INCREMENT,
    comment VARCHAR(100) NOT NULL DEFAULT "",

    PRIMARY KEY (id)
);

INSERT INTO `tbl_table1` (comment) VALUES ('asd');
INSERT INTO `tbl_table1` (comment) VALUES ('asd1');
INSERT INTO `tbl_table1` (comment) VALUES ('asd2');
INSERT INTO `tbl_table2` (comment) VALUES ('qqqqqqqqqqqq');
INSERT INTO `tbl_table2` (comment) VALUES ('aaaaaaaaaaaa');

INSERT INTO `tbl_users` (login,pass,comment) VALUES ('user1','password1','test user');
INSERT INTO `tbl_users` (login,pass,comment) VALUES ('user2','password2','test user');
INSERT INTO `tbl_users` (login,pass,comment) VALUES ('user3','password3','test user');

-- Replication settings
