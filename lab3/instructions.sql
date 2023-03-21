SET SERVEROUTPUT ON SIZE UNLIMITED;
CREATE OR REPLACE 
PROCEDURE COMPARE_SCHEMA(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
IS
    counter NUMBER;
    counter2 NUMBER;
    text VARCHAR2(100);
BEGIN
-- dev tables to create or add columns in prod
FOR res IN (Select  DISTINCT table_name from all_tab_columns where owner = dev_schema_name  and (table_name, column_name) not in
        (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
    LOOP
        counter := 0;
        SELECT COUNT(*) INTO counter FROM all_tables where owner = prod_schema_name and table_name = res.table_name;
        IF counter > 0 THEN
            FOR res2 IN (Select  DISTINCT column_name,data_type from all_tab_columns where owner = dev_schema_name and table_name = res.table_name  and (table_name, column_name) not in
                        (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
                        LOOP
                            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || prod_schema_name || '.' || res.table_name || ' ADD ' || res2.column_name || ' ' || res2.data_type || ';');
                        END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || prod_schema_name || '.' || res.table_name || ' AS (SELECT * FROM ' || res.table_name || ' WHERE 1=0);');
        END IF;
    END LOOP;
    
-- prod tables to delete or drop columns
FOR res IN (Select  DISTINCT table_name from all_tab_columns where owner = prod_schema_name  and (table_name, column_name) not in
        (select table_name, column_name from all_tab_columns where owner = dev_schema_name))
    LOOP
        counter := 0;
        counter2 :=0;
        SELECT COUNT(column_name) INTO counter FROM all_tab_columns where owner = prod_schema_name and table_name = res.table_name;
        SELECT COUNT(column_name) INTO counter2 FROM all_tab_columns where owner = dev_schema_name and table_name = res.table_name;
        IF counter != counter2 THEN
            FOR res2 IN (select column_name from all_tab_columns where owner = prod_schema_name and table_name = res.table_name and 
                            column_name not in (select column_name from all_tab_columns where owner = dev_schema_name and table_name = res.table_name))
                        LOOP
                            DBMS_OUTPUT.PUT_LINE('ALTER TABLE '|| prod_schema_name || '.' || res.table_name || ' DROP COLUMN ' || res2.column_name || ';');
                        END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('DROP TABLE ' || prod_schema_name || '.' || res.table_name || ' CASCADE CONSTRAINTS;');
        END IF;
    END LOOP;
    
-- dev procedure to create in prod
FOR res IN (select DISTINCT object_name from all_objects where object_type='PROCEDURE' and owner=dev_schema_name  and object_name not in
        (select object_name from all_objects where owner = prod_schema_name and object_type='PROCEDURE'))
    LOOP
        counter := 0;   
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (select text from all_source where type='PROCEDURE' and name=res.object_name and owner=dev_schema_name)
            LOOP
                IF COUNTER != 0 THEN
                    DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
                ELSE
                   DBMS_OUTPUT.PUT_LINE(rtrim(prod_schema_name || '.' || res2.text,chr (10) || chr (13)));
                   counter := 1;
                END IF;
            END LOOP;
    END LOOP;   

-- prod procedures to delete

FOR res IN (select DISTINCT object_name from all_objects where object_type='PROCEDURE' and owner=prod_schema_name and object_name not in
        (select object_name from all_objects where owner = dev_schema_name and object_type='PROCEDURE'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP PROCEDURE ' || prod_schema_name || '.' || res.object_name);
    END LOOP;   

--dev functions to create in prod
FOR res IN (select DISTINCT object_name from all_objects where object_type='FUNCTION' and owner=dev_schema_name  and object_name not in
        (select object_name from all_objects where owner = prod_schema_name and object_type='FUNCTION'))
    LOOP
        counter := 0;   
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (select text from all_source where type='FUNCTION' and name=res.object_name and owner=dev_schema_name)
            LOOP
                IF COUNTER != 0 THEN
                    DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
                ELSE
                   DBMS_OUTPUT.PUT_LINE(rtrim(prod_schema_name || '.' || res2.text,chr (10) || chr (13)));
                   counter := 1;
                END IF;
            END LOOP;
    END LOOP; 

--prod functions to delete
FOR res IN (select DISTINCT object_name from all_objects where object_type='FUNCTION' and owner=prod_schema_name and object_name not in
        (select object_name from all_objects where owner = dev_schema_name and object_type='FUNCTION'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP FUNCTION ' || prod_schema_name || '.' || res.object_name);
    END LOOP;  
    
--dev indexes to create in prod
FOR res IN (select  index_name, index_type, table_name from all_indexes where table_owner=dev_schema_name and index_name not like '%_PK' and index_name not in
        (select index_name from all_indexes where table_owner=prod_schema_name and index_name not like '%_PK'))
    LOOP
        select column_name INTO text from ALL_IND_COLUMNS where index_name=res.index_name and table_owner=dev_schema_name;
        DBMS_OUTPUT.PUT_LINE('CREATE ' || res.index_type || ' INDEX ' || res.index_name || ' ON ' || prod_schema_name || '.' || res.table_name || '(' || text || ');');
    END LOOP;

--delete indexes drom prod
FOR res IN (select  index_name from all_indexes where table_owner= prod_schema_name  and index_name not like '%_PK' and index_name not in
        (select index_name from all_indexes where table_owner=dev_schema_name and index_name not like '%_PK'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP INDEX ' || res.index_name || ';');
    END LOOP;

END;


exec COMPARE_SCHEMA('AUSER','PROD');

