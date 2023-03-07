SET SERVEROUTPUT ON SIZE UNLIMITED;
CREATE OR REPLACE 
PROCEDURE COMPARE_SCHEMA(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
IS
    counter NUMBER;
    counter2 NUMBER;
    text VARCHAR2(100);
BEGIN

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