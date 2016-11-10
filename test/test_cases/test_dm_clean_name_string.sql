SELECT
  observed = expected AS test_passed,
  'valid_string_unchanged' AS test_name,
  *
FROM (
  SELECT
    *,
    openclinica_fdw.dm_clean_name_string(input_value) AS observed
  FROM (
    SELECT
      'this_string_here' :: TEXT AS input_value,
      'this_string_here' :: TEXT AS expected
  ) AS inputs
) as test;

SELECT
  observed = expected AS test_passed,
  'lower_case_invalid_chars' AS test_name,
  *
FROM (
  SELECT
    *,
    openclinica_fdw.dm_clean_name_string(input_value) AS observed
  FROM (
    SELECT
      'this/string ~here'::text AS input_value,
      'this_u2f_string__u7e_here'::text AS expected
  ) AS inputs
) as test;

SELECT
  observed = expected AS test_passed,
  'upper_case_invalid_chars' AS test_name,
  *
FROM (
  SELECT
    *,
    openclinica_fdw.dm_clean_name_string(input_value) AS observed
  FROM (
    SELECT
      'This/strIng -HERE'::text AS input_value,
      'this_u2f_string__u2d_here'::text AS expected
  ) AS inputs
) as test;

SELECT
  observed = expected AS test_passed,
  'upper_case_spaces_only' AS test_name,
  *
FROM (
  SELECT
    *,
    openclinica_fdw.dm_clean_name_string(input_value) AS observed
  FROM (
    SELECT
      'THIS STRING HERE'::text AS input_value,
      'this_string_here'::text AS expected
  ) AS inputs
) as test;

SELECT
  observed = expected AS test_passed,
  'high_range_character' AS test_name,
  *
FROM (
  SELECT
    *,
    openclinica_fdw.dm_clean_name_string(input_value) AS observed
  FROM (
    SELECT
      'yay 😊 a happy smiley_face'::text AS input_value,
      'yay__u1f60a__a_happy_smiley_face'::text AS expected
  ) AS inputs
) as test;