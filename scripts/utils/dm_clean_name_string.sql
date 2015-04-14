CREATE OR REPLACE FUNCTION openclinica_fdw.dm_clean_name_string(
  name_string TEXT
)
  RETURNS TEXT AS
  $BODY$
    SELECT
        lower(
                regexp_replace(
                        regexp_replace(
                                name_string,
                                $$[^\w\s]$$,
                                $$$$,
                                $$g$$
                        ),
                        $$[\s]$$,
                        $$_$$,
                        $$g$$
                )
        ) AS cleaned_name_string;
    $BODY$ LANGUAGE SQL STABLE;