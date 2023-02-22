CREATE TABLE Groups(
     id NUMBER PRIMARY KEY,
     Name VARCHAR2(100) NOT NULL,
     CVal NUMBER NOT NULL);    

CREATE TABLE Students
(
Id NUMBER PRIMARY KEY,
Name VARCHAR2(100) NOT NULL,
GroupId NUMBER REFERENCES Groups (Id)
)


#task 2

CREATE SEQUENCE group_id_increment
MINVALUE 1 MAXVALUE 10000000
INCREMENT BY 1 START WITH 1 CACHE 20;

CREATE SEQUENCE student_id_increment
MINVALUE 1 MAXVALUE 10000000
INCREMENT BY 1 START WITH 1 CACHE 20;


CREATE OR REPLACE TRIGGER generate_student_id
  BEFORE INSERT ON Students
  FOR EACH ROW
BEGIN
  :new.id := student_id_increment.nextval;
END;

CREATE OR REPLACE TRIGGER generate_group_id
  BEFORE INSERT ON Groups
  FOR EACH ROW
BEGIN
  :new.id := group_id_increment.nextval;
END;

INSERT INTO MYSCHEMA.GROUPS (id, name, CVAL) VALUES(1, '053501', 30);
INSERT INTO MYSCHEMA.GROUPS(id, name, CVAL) VALUES(2, '053502', 30);
INSERT INTO MYSCHEMA.GROUPS(id, Name, CVal) VALUES(3, '053503', 30);
INSERT INTO MYSCHEMA.GROUPS(id, name, CVAL) VALUES(5, '053505', 30)



INSERT INTO MYSCHEMA.students(name, groupId) VALUES('Alena', 20);
INSERT INTO MYSCHEMA.students(name, groupId) VALUES('Natalia', 21)
INSERT INTO MYSCHEMA.students(name, groupId) VALUES('Nile', 22);


CREATE OR REPLACE TRIGGER unique_group_name
BEFORE UPDATE
ON groups FOR EACH ROW
DECLARE
id_ NUMBER;
existing_name EXCEPTION;
BEGIN
        SELECT id INTO id_ FROM groups WHERE groups.name=:NEW.name;
        dbms_output.put_line('This name already exists'||:NEW.name);
        raise existing_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;


CREATE OR REPLACE TRIGGER unique_group_id
BEFORE UPDATE OR INSERT
ON groups FOR EACH ROW
FOLLOWS UNIQUE_GROUP_NAME
DECLARE
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
        SELECT groups.id INTO id_ FROM groups WHERE groups.id=:NEW.id;
               dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;



CREATE OR REPLACE TRIGGER unique_student_id
BEFORE UPDATE OR INSERT
ON students FOR EACH ROW
DECLARE
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
        SELECT students.id INTO id_ FROM students WHERE students.id=:NEW.id;
        dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;

#Task 3
CREATE OR REPLACE TRIGGER fk_group
AFTER DELETE 
ON MYSCHEMA.GROUPS  FOR EACH ROW
BEGIN
    DELETE FROM MYSCHEMA.STUDENTS WHERE groupId=:OLD.Id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('students in group arent exists'||:OLD.id);   
END;


#task4
CREATE TABLE Journal (
    id NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
    operation VARCHAR2(2) NOT NULL,
    date_of_writting TIMESTAMP NOT NULL,
    student_id NUMBER,
    student_name VARCHAR2(100) NOT NULL,
    student_group_id NUMBER
);

CREATE OR REPLACE TRIGGER journal_students
AFTER UPDATE OR INSERT OR DELETE
ON MYSCHEMA.STUDENTS  FOR EACH ROW
BEGIN
    CASE
	    WHEN deleting THEN 
        	INSERT INTO MYSCHEMA.JOURNAL(operation,date_of_writting,student_id,student_name,student_group_id) VALUES (
            'D', CURRENT_TIMESTAMP, :OLD.id, :OLD.name, :OLD.groupId);
        WHEN inserting THEN
            INSERT INTO MYSCHEMA.JOURNAL(operation,date_of_writting,student_id,student_name,student_group_id)  VALUES (
            'I', CURRENT_TIMESTAMP, :NEW.id, :NEW.name, :NEW.groupId);
        WHEN updating THEN
             INSERT INTO MYSCHEMA.JOURNAL(operation,date_of_writting,student_id,student_name,student_group_id)  VALUES (
            'BU', CURRENT_TIMESTAMP, :OLD.id, :OLD.name, :OLD.groupId);
             INSERT INTO MYSCHEMA.JOURNAL(operation,date_of_writting,student_id,student_name,student_group_id) VALUES (
            'AU', CURRENT_TIMESTAMP, :NEW.id, :NEW.name, :NEW.groupId);   
    END CASE;
END;