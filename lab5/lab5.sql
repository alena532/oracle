ALTER USER LAB5 quota unlimited ON USERS;
-- first
CREATE TABLE FACULTIES
(
    id           NUMBER UNIQUE NOT NULL,
    name         VARCHAR2(50)  NOT NULL,
    date_founded DATE          NOT NULL
);

CREATE TABLE GROUPS
(
    id         NUMBER UNIQUE NOT NULL,
    name       VARCHAR2(50)  NOT NULL,
    faculty_id NUMBER        NOT NULL,
    CONSTRAINT fk_fc FOREIGN KEY (faculty_id) REFERENCES FACULTIES (id) ON DELETE CASCADE
);

CREATE TABLE STUDENTS
(
    id       NUMBER UNIQUE NOT NULL,
    name     VARCHAR2(50)  NOT NULL,
    group_id NUMBER        NOT NULL,
    CONSTRAINT fk_gr FOREIGN KEY (group_id) REFERENCES GROUPS (id) ON DELETE CASCADE
);

CREATE TABLE LOG_FACULTIES
(
    operation    VARCHAR(10) NOT NULL,
    id           NUMBER,
    old_name     VARCHAR(50),
    new_name     VARCHAR(50),
    date_founded DATE,
    tm           TIMESTAMP   NOT NULL
);

CREATE TABLE LOG_GROUPS
(
    operation  VARCHAR(10) NOT NULL,
    id         NUMBER,
    old_name   VARCHAR(50),
    new_name   VARCHAR(50),
    faculty_id NUMBER,
    tm         TIMESTAMP   NOT NULL
);

CREATE TABLE LOG_STUDENTS
(
    operation VARCHAR(10) NOT NULL,
    id        NUMBER,
    old_name  VARCHAR(50),
    new_name  VARCHAR(50),
    group_id  NUMBER,
    tm        TIMESTAMP   NOT NULL
);
CREATE OR REPLACE TRIGGER LOG_FC_INS
    AFTER INSERT
    ON FACULTIES
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_FACULTIES(operation, id, new_name, old_name, date_founded, tm)
    VALUES ('INSERT', :new.id, NULL, NULL, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_FC_UPD
    AFTER UPDATE
    ON FACULTIES
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_FACULTIES(operation, id, new_name, old_name, date_founded, tm)
    VALUES ('UPDATE', :new.id, :new.name, :old.name, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_FC_DEL
    AFTER DELETE
    ON FACULTIES
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_FACULTIES(operation, id, new_name, old_name, date_founded, tm)
    VALUES ('DELETE', :old.id, :old.name, NULL, :old.date_founded, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_GR_INS
    AFTER INSERT
    ON GROUPS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_GROUPS(operation, id, new_name, old_name, faculty_id, tm)
    VALUES ('INSERT', :new.id, NULL, NULL, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_GR_UPD
    AFTER UPDATE
    ON GROUPS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_GROUPS(operation, id, new_name, old_name, faculty_id, tm)
    VALUES ('UPDATE', :new.id, :new.name, :old.name, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_GR_DEL
    AFTER DELETE
    ON GROUPS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_GROUPS(operation, id, new_name, old_name, faculty_id, tm)
    VALUES ('DELETE', :old.id, :old.name, NULL, :old.faculty_id, current_timestamp);
END;

--log students

CREATE OR REPLACE TRIGGER LOG_ST_INS
    AFTER INSERT
    ON STUDENTS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_STUDENTS(operation, id, new_name, old_name, group_id, tm)
    VALUES ('INSERT', :new.id, NULL, NULL, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_ST_UPD
    AFTER UPDATE
    ON STUDENTS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_STUDENTS(operation, id, new_name, old_name, group_id, tm)
    VALUES ('UPDATE', :new.id, :new.name, :old.name, NULL, current_timestamp);
END;

CREATE OR REPLACE TRIGGER LOG_ST_DEL
    AFTER DELETE
    ON STUDENTS
    FOR EACH ROW
BEGIN
    INSERT INTO LOG_STUDENTS(operation, id, new_name, old_name, group_id, tm)
    VALUES ('DELETE', :old.id, :old.name, NULL, :old.group_id, current_timestamp);
END;

