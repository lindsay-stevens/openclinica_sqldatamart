CREATE OR REPLACE FUNCTION openclinica_fdw.dm_clean_name_string(
  IN  name_string    TEXT,
  OUT cleaned_string TEXT
) AS $b$
/*
Return a string in a form that would be valid in an identifier.

- Replace one or more sequential whitespace characters with aunderscores,
- Replace other invalid characters with their UTF-8 hex code,
  prefixed with 'u' and wrapped in underscores,
- Lowercase the result.

Assumes that if the string is the entire identifier, then the calling
function will prefix an initial invalid character [^a-zA-Z_] with an underscore.

Example: 'this/string Here' becomes 'this_u2fd_string_here'.
*/

SELECT string_agg(
         CASE
         WHEN text_as_rows.text_char ~ $r$[\w]$r$
           THEN text_as_rows.text_char
         ELSE concat($s$_u$s$, to_hex(ascii(text_as_rows.text_char)), $s$_$s$)
         END,
         $s$$s$) AS cleaned_string
FROM
  (
    SELECT with_subscripts.text_array [with_subscripts.subscripts] AS text_char
    FROM
      (
        SELECT
          generate_subscripts(to_array.text_array, 1) AS subscripts,
          to_array.text_array
        FROM
          (
            SELECT regexp_split_to_array(
                     replace(lower(name_string), $s$ $s$, $s$_$s$),
                     $s$$s$) AS text_array
          ) AS to_array
      ) AS with_subscripts
  ) AS text_as_rows;

$b$ LANGUAGE SQL IMMUTABLE;