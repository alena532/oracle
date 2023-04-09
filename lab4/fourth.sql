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

    
END;

