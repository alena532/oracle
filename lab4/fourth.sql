CREATE OR REPLACE PACKAGE JSON_PARSER IS
    FUNCTION Parse_Arg(l_element JSON_ELEMENT_T) RETURN CLOB;
END JSON_PARSER;

CREATE OR REPLACE PACKAGE BODY JSON_PARSER IS

    FUNCTION Parse_Array_Args(l_json_array JSON_ARRAY_T, separator CLOB) RETURN CLOB
        IS
        temp    CLOB;
        res     CLOB    := '';
        isFirst BOOLEAN := TRUE;
        counter integer;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                temp := Parse_Arg(l_json_array.get(counter));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp := CONCAT(separator, temp);
                END IF;
                res := CONCAT(res, temp);
            END LOOP;
        return res;
    END;

    FUNCTION Parse_Array_Args(l_json_array JSON_KEY_LIST, separator CLOB) RETURN CLOB
        IS
        temp    CLOB;
        res     CLOB    := '';
        isFirst BOOLEAN := TRUE;
        counter integer;
    BEGIN
        FOR counter IN 1 .. l_json_array.COUNT
            LOOP
                temp := l_json_array(counter);
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp := CONCAT(separator, temp);
                END IF;
                res := CONCAT(res, temp);
            END LOOP;
        return res;
    END;

    FUNCTION Make_Operation(LHS CLOB, RHS CLOB, operation CLOB) RETURN CLOB
        IS
    BEGIN
        return LHS || ' ' || operation || ' ' || RHS;
    END;

    FUNCTION Get_Operation(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_OPERATION EXCEPTION;
        PRAGMA exception_init (UNKNOWN_OPERATION , -20001 );
        ex        VARCHAR2(10) := 'UNKNOWN';
        res       CLOB;
        operation CLOB;
    BEGIN
        operation := UPPER(l_object.get_string('OPERATOR'));
        res := CASE
                   WHEN
                       operation in ('=', '!=', '<>', '<', '>', '>=', '<=')
                       THEN Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')), operation)
                   WHEN operation in ('IN', 'NOT IN') THEN Make_Operation(Parse_Arg(l_object.get('LHS')), '(' ||
                                                                                                          Parse_Array_Args(l_object.get_array('RHS'), ', ') ||
                                                                                                          ')',
                                                                          operation)
                   WHEN operation in ('EXISTS', 'NOT EXISTS')
                       THEN operation || ' (' || Parse_Arg(l_object.get('RHS')) || ')'
                   ELSE ex
            END;
        IF res = ex THEN raise_application_error(-20001, 'Unknown operation: ' || operation); END IF;
        return res;
    END;

    FUNCTION GET_WHERE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        UNKNOWN_WHERE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_WHERE , -20002 );
        ex       VARCHAR2(10) := 'UNKNOWN';
        counter  integer;
        res      CLOB         := '';
        temp_str CLOB;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                temp_str := CASE
                                WHEN l_object.has('SEPARATOR') = TRUE THEN l_object.get_string('SEPARATOR')
                                WHEN l_object.has('OPERATOR') = TRUE THEN Get_Operation(l_object)
                                ELSE ex
                    END;
                IF temp_str = ex THEN
                    raise_application_error(-20002, 'Unknown where command: ' || l_object.to_string());
                END IF;
                res := CONCAT(res, CONCAT(' ', temp_str));
            END LOOP;
        return res;
    END;

    FUNCTION Get_Select_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t  CLOB;
        select_name_t CLOB;
        where_t       CLOB;
        into_t        CLOB;
        res_str       CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        select_name_t := Parse_array_Args(l_object.get_array('VALUES'), ', ');
        res_str := TO_CLOB('SELECT ' || select_name_t);
        IF l_object.has('INTO') = TRUE THEN
            into_t := Parse_Array_Args(l_object.get_array('INTO'), ', ');
            res_str := CONCAT(res_str, ' INTO ' || into_t);
        END IF;
        res_str := CONCAT(res_str, ' FROM ' || table_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_Insert_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t  CLOB;
        select_name_t CLOB;
        insert_name_t CLOB;
        where_t       CLOB;
        res_str       CLOB;
        temp_str      CLOB;
        l_key_list    json_key_list;
        l_object_temp JSON_OBJECT_T;
        isFirst       BOOLEAN := TRUE;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        l_object_temp := l_object.get_object('VALUES');
        l_key_list := l_object_temp.get_Keys();
        FOR counter IN 1 .. l_key_list.COUNT
            LOOP
                temp_str := Parse_Arg(l_object_temp.get(l_key_list(counter)));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', temp_str);
                END IF;
                insert_name_t := CONCAT(insert_name_t, temp_str);
            END LOOP;
        select_name_t := Parse_Array_Args(l_key_list, ', ');
        res_str :=
                TO_CLOB('INSERT INTO ' || table_name_t || '(' || select_name_t || ') VALUES (' || insert_name_t || ')');
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_UPDATE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        counter  integer;
        res      CLOB    := '';
        temp_str CLOB;
        isFirst  BOOLEAN := TRUE;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                IF isFirst = TRUE THEN
                    temp_str := Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')), '=');
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ',
                                       Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')),
                                                      '='));
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION Get_Update_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        set_name_t   CLOB;
        where_t      CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        set_name_t := Get_UPDATE_TO_CLOB(l_object.get_array('VALUES'));
        res_str := TO_CLOB('UPDATE ' || table_name_t || ' SET ' || set_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_Delete_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        where_t      CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        res_str := TO_CLOB('DELETE FROM ' || table_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_COLUMS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        UNKNOWN_UPDATE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_UPDATE , -20004 );
        counter  integer;
        res      CLOB    := '';
        temp_str CLOB;
        str      CLOB;
        isFirst  BOOLEAN := TRUE;
        other_t  CLOB;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                str := parse_arg(l_object.get('NAME')) || ' ' || parse_arg(l_object.get('TYPE'));
                IF isFirst = TRUE THEN
                    temp_str := str;
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', str);
                END IF;
                IF l_object.has('OTHER') = TRUE THEN
                    other_t := Parse_Array_Args(l_object.get_array('OTHER'), ' ');
                    temp_str := CONCAT(temp_str, ' ' || other_t);
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION Get_OTHER_OPTIONS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
    BEGIN
        return parse_array_args(l_json_array, ' ');
    END;

    FUNCTION Get_Create_Table_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        colums_t     CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('NAME');
        colums_t := Get_COLUMS_TO_CLOB(l_object.get_array('COLUMS'));
        res_str := TO_CLOB('CREATE TABLE ' || table_name_t || '(' || colums_t || ')');
        return res_str;
    END;

    FUNCTION Get_Create_Sequence_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        sequence_name_t CLOB;
        res_str         CLOB;
    BEGIN
        sequence_name_t := l_object.get_string('NAME');
        res_str := TO_CLOB('CREATE SEQUENCE ' || sequence_name_t);
        return res_str;
    END;

    
END;

