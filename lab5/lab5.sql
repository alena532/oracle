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
