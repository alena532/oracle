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

    
END;

