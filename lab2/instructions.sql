dCREATE TABLE Groups(
     id NUMBER PRIMARY KEY,
     Name VARCHAR2(100) NOT NULL,
     CVal NUMBER NOT NULL);    

CREATE TABLE Students
(
Id NUMBER PRIMARY KEY,
Name VARCHAR2(100) NOT NULL,
GroupId Number NULL
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
BEFORE UPDATE OR INSERT
ON MYSCHEMA.GROUPS  FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
id_ NUMBER;
existing_name EXCEPTION;
BEGIN
    case
    when updating then
        if :NEW.Name NOT LIKE :OLD.Name then
        SELECT id INTO id_ FROM MYSCHEMA.GROUPS  WHERE MYSCHEMA.GROUPS.Name= :NEW.Name;
        dbms_output.put_line('This name already exists'||:NEW.Name);
        raise existing_name;
        end if;
    when inserting then 
        SELECT groups.id INTO id_ FROM groups WHERE groups.Name=:NEW.Name;
        dbms_output.put_line('An id already exists'||:NEW.Name);
        raise existing_name;
    end case;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;

CREATE OR REPLACE TRIGGER unique_group_id
BEFORE UPDATE OR INSERT
ON MYSCHEMA.GROUPS FOR EACH ROW
FOLLOWS UNIQUE_GROUP_NAME
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
    case
    when updating then 
        if :NEW.Id NOT LIKE :OLD.Id then
        SELECT id INTO id_ FROM MYSCHEMA.GROUPS WHERE MYSCHEMA.GROUPS.id= :NEW.id;
            dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
        end if;
    when inserting then 
        SELECT id INTO id_ FROM MYSCHEMA.GROUPS WHERE MYSCHEMA.GROUPS.id= :NEW.id;
            dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
    end case;    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;




CREATE OR REPLACE TRIGGER unique_student_id
BEFORE UPDATE OR INSERT
ON MYSCHEMA.students FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
    case
    when updating then 
        if :NEW.Id NOT LIKE :OLD.Id then
        SELECT id INTO id_ FROM MYSCHEMA.students WHERE MYSCHEMA.students.id= :NEW.id;
            dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
        end if;
    when inserting then 
        SELECT id INTO id_ FROM MYSCHEMA.students WHERE MYSCHEMA.students.id= :NEW.id;
            dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
    end case;    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('success');
END;

#Task 3
CREATE OR REPLACE TRIGGER fk_group
after DELETE 
ON MYSCHEMA.GROUPS FOR EACH ROW
BEGIN
    DELETE FROM MYSCHEMA.STUDENTS WHERE groupId=:OLD.Id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('students in group arent exists'||:OLD.id);
END;

TRIGGER fk_student_group
BEFORE INSERT OR UPDATE  
ON MYSCHEMA.STUDENTS  FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
id_ NUMBER;
BEGIN
	CASE
	WHEN inserting THEN
	SELECT id INTO id_ FROM MYSCHEMA.GROUPS WHERE id=:NEW.groupId;
	WHEN updating THEN
	IF :NEW.groupId NOT LIKE :OLD.groupId THEN
	SELECT id INTO id_ FROM MYSCHEMA.GROUPS WHERE id=:NEW.groupId;
	END IF;
	END CASE;
    
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
DECLARE
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

#task 6

CREATE OR REPLACE TRIGGER C_val_group
before UPDATE OR INSERT OR DELETE
ON STUDENTS FOR EACH ROW
DECLARE
gr_id NUMBER;
val NUMBER;
val_before NUMBER;
BEGIN
    CASE
     WHEN deleting THEN 
       SELECT cVal INTO val FROM GROUPS WHERE id = :OLD.groupId;
         if :OLD.groupId LIKE NULL then
         return;
         end if;
         UPDATE GROUPS 
         SET cVal = val-1
         WHERE id = :OLD.groupId;
     WHEN inserting THEN
        SELECT cVal INTO val FROM GROUPS WHERE id = :NEW.groupId;
         UPDATE GROUPS 
         SET cVal = val+1
         WHERE id = :new.groupId; 
     WHEN updating THEN
       SELECT cVal INTO val FROM GROUPS WHERE id = :NEW.groupId;
       SELECT cVal INTO val_before FROM GROUPS WHERE id = :OLD.groupId;
         UPDATE GROUPS 
         SET cVal = val+1
         WHERE id = :NEW.groupId;
        UPDATE GROUPS 
         SET cVal = val_before-1
         WHERE id = :OLD.groupId;
    END CASE;
EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   dbms_output.put_line('Nothing change');
END;


#task 5

CREATE OR REPLACE PROCEDURE student_rollback(time_rollback_first TIMESTAMP) 
IS
CURSOR jrnl_row IS SELECT * FROM MYSCHEMA.JOURNAL ORDER BY date_of_writting DESC;
wrong EXCEPTION;
BEGIN  
  DELETE STUDENTS;
    FOR r_journal IN jrnl_row LOOP
    	IF r_journal.date_of_writting < time_rollback_first THEN 
            IF r_journal.operation = 'I' THEN
                        dbms_output.put_line(r_journal.operation);
                INSERT INTO students VALUES(r_journal.student_id, r_journal.student_name, r_journal.student_group_id);
            ELSIF r_journal.operation = 'D' THEN
                        dbms_output.put_line(r_journal.operation);
                DELETE FROM students WHERE id=r_journal.student_id;
            ELSIF r_journal.operation = 'AU' THEN
                UPDATE students SET 
                  name=r_journal.student_name,
                  groupId=r_journal.student_group_id
                WHERE students.id=r_journal.student_id;

            ELSE 
                RAISE wrong;
            END IF;
        END IF;
    END LOOP;
   EXCEPTION
       WHEN wrong THEN
       dbms_output.put_line('WRONG!');
END;
    
CALL student_rollback(TO_TIMESTAMP('23.02.23 18:42:00'));

CALL student_rollback(TO_TIMESTAMP('3.06.2023 19:45:00'));