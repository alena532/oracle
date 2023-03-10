CREATE TABLE MyTable
(
    id NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
    val NUMBER
)

DECLARE
begin_value integer := 1;
end_value integer := 10000;
BEGIN
   FOR l_current_year IN  begin_value .. end_value
   LOOP
      INSERT INTO MyTable (val) 
     VALUES (round(dbms_random.value(1,10000)));
   END LOOP;
END ;

CREATE OR REPLACE FUNCTION checking_values
RETURN VARCHAR IS
odd_elements integer;
even_elements integer;
result varchar(5);
BEGIN
   select count(*) into odd_elements from myTable
    where mod(val,2)=1;
    select count(*) into even_elements from myTable
    where mod(val,2)=0;
    if even_elements > odd_elements then 
        result:='true';
        return result;
    elsif even_elements < odd_elements then 
        result:='false';
        return result;  
      elsif even_elements = odd_elements then 
        result:='equal';
        return result;   
       end if; 
END;


declare 
c varchar(20);
  begin
   c  := checking_values();  
   dbms_output.put_line( c);  
 end;
  
  
create or replace NONEDITIONABLE FUNCTION getInsert (row_id IN number )
RETURN VARCHAR IS res varchar(80);
    inserted_val number;
    val_missing EXCEPTION;
BEGIN
      SELECT val into inserted_val from myTable
      where Id = row_id;
      IF inserted_val IS NULL then
        RAISE val_missing;       
      else 
        res :=  'insert into myTable (id, name) values('|| row_id ||','|| inserted_val ||')';
      end if;  
   return res;
END;

declare
  c varchar(80);
  begin
   c  :=  totalCustomers(3);  
   dbms_output.put_line('Total no. of Customers: ');  
 end;


 create or replace NONEDITIONABLE PROCEDURE insertOperations (row_value IN number ) IS
BEGIN
      INSERT INTO MyTable (val)
      VALUES (row_value);
END;


create or replace NONEDITIONABLE PROCEDURE updateOperations (row_id in number,row_value IN number ) IS
any_rows_found number;
id_missing EXCEPTION;
BEGIN
  select count(*)
  into   any_rows_found
  from   mytable
  where id = row_id;
  if any_rows_found = 1 then
      update  MyTable 
      set val = row_value
      where id = row_id;
  else   
      raise id_missing;
  End IF;
end;  
  


create or replace NONEDITIONABLE PROCEDURE deleteOperations (row_id in number ) IS
any_rows_found number;
id_missing EXCEPTION;
BEGIN
      select count(*)
  into   any_rows_found
  from   mytable
  where id = row_id;
  if any_rows_found = 1 then
      delete  MyTable 
      where id = row_id;
  else   
      raise id_missing;
  end if;    
END;

create or replace NONEDITIONABLE FUNCTION get_year_income(monthly_income NUMBER, adding_percent NUMBER) 
RETURN VARCHAR2
IS
    result_value REAL;
    wrong_percent EXCEPTION;
BEGIN   
    IF adding_percent < 0 or monthly_income<0 THEN
        RAISE wrong_percent;        
    END IF;        
    result_value := (1 + adding_percent/100)*12*monthly_income;
    RETURN  utl_lms.format_message('%d', TO_CHAR(result_value));

    EXCEPTION
        WHEN INVALID_NUMBER THEN
            RETURN utl_lms.format_message('Wrong input type');
        WHEN wrong_percent THEN
            RETURN utl_lms.format_message('Wrong percent');
        WHEN ZERO_DIVIDE THEN 
            RETURN utl_lms.format_message('%d', TO_CHAR(monthly_income * 12));
END;

DECLARE
    res VARCHAR2(100);
BEGIN
    SELECT get_year_income(12, 13) INTO res from DUAL;
    dbms_output.put_line(res);
    
    EXCEPTION
        WHEN INVALID_NUMBER THEN
             dbms_output.put_line('Wrong input type');
END;