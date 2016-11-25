CREATE OR REPLACE FUNCTION openclinica_fdw.dm_clean_try_cast_value(
  IN    data_type_id INTEGER,
  INOUT data_text    TEXT,
  OUT   data_numeric NUMERIC,
  OUT   data_date    DATE,
  OUT   cast_failure BOOLEAN
) AS
$b$
/*
Clean and try to cast a value to a corresponding PostgreSQL type, if any.

Successful casts are returned in the out parameter corresponding to that type.
If the cast fails, the exception is suppressed, "cast_failure" is true; this
mechanism replaces the need to check for "null codes".
*/
BEGIN
  /* Initialise output variables to null */
  data_numeric := NULL;
  data_date := NULL;
  cast_failure := FALSE;

  CASE
  /* If the value is zero or more whitespaces (lazy), nullify it. */
    WHEN data_text ~ $r$^[\s]*?$$r$
    THEN data_text := NULL;
  ELSE
  END CASE;

  /* From item_data_type.code. 6=INT, 7=REAL, 9=DATE. Others treated as text. */
  CASE data_type_id
    WHEN 6, 7
    THEN data_numeric := CAST(data_text AS NUMERIC);
    WHEN 9
    THEN data_date := CAST(data_text AS DATE);
  ELSE
  END CASE;

  EXCEPTION
  WHEN SQLSTATE '22007' /* invalid_datetime_format (bad date value) */
    THEN
      cast_failure := TRUE;
  WHEN SQLSTATE '22P02' /* invalid_text_representation (bad numeric value) */
    THEN
      cast_failure := TRUE;

END;$b$ LANGUAGE plpgsql IMMUTABLE;
