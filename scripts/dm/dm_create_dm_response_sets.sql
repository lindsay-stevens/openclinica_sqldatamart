CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_response_sets()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.response_sets AS
        SELECT
            rs_opt_text.version_id,
            rs_opt_text.response_set_id,
            rs_opt_text.label,
            rs_opt_text.option_text,
            rs_opt_value.option_value,
            rs_opt_text.option_order
        FROM
            (
                SELECT
                    version_id,
                    response_set_id,
                    label,
                    replace(
                            option_text,
                            $$##@##@##$$,
                            $$,$$
                    ) AS option_text,
                    option_order
                FROM
                    (
                        SELECT
                            version_id,
                            response_set_id,
                            label,
                            trim(
                                    BOTH
                                    FROM
                                    (
                                        option_text_array [
                                        option_order
                                        ]
                                    )
                            ) AS option_text,
                            option_order
                        FROM
                            (
                                SELECT
                                    version_id,
                                    response_set_id,
                                    label,
                                    option_text_array,
                                    generate_subscripts(
                                            option_text_array,
                                            1
                                    ) AS option_order
                                FROM
                                    (
                                        SELECT
                                            version_id,
                                            response_set_id,
                                            label,
                                            string_to_array(
                                                    option_text,
                                                    $$,$$
                                            ) AS option_text_array
                                        FROM
                                            (
                                                SELECT
                                                    version_id,
                                                    response_set_id,
                                                    label,
                                                    replace(
                                                            options_text,
                                                            $$\,$$,
                                                            $$##@##@##$$
                                                    ) AS option_text
                                                FROM
                                                    response_set
                                                WHERE
                                                    response_type_id IN
                                                    (
                                                        3, 5, 6, 7
                                                    )
                                            ) AS rs_text_replace
                                    ) AS rs_opt_array
                            ) AS rs_opt_array_rownum
                    ) AS rs_opt_split
            ) AS rs_opt_text
            INNER JOIN
            (
                SELECT
                    version_id,
                    response_set_id,
                    label,
                    trim(
                            BOTH
                            FROM
                            (
                                option_value_array [
                                option_order
                                ]
                            )
                    ) AS option_value,
                    option_order
                FROM
                    (
                        SELECT
                            version_id,
                            response_set_id,
                            label,
                            option_value_array,
                            generate_subscripts(
                                    option_value_array,
                                    1
                            ) AS option_order
                        FROM
                            (
                                SELECT
                                    version_id,
                                    response_set_id,
                                    label,
                                    string_to_array(
                                            options_values,
                                            $$,$$
                                    ) AS option_value_array
                                FROM
                                    response_set
                                WHERE
                                    response_type_id IN (
                                        3, 5, 6, 7
                                    )
                            ) AS rs_opt_array
                    ) AS rs_opt_array_rownum
            ) AS rs_opt_value
                ON rs_opt_text.version_id = rs_opt_value.version_id
                   AND
                   rs_opt_text.response_set_id = rs_opt_value.response_set_id
                   AND rs_opt_text.option_order = rs_opt_value.option_order
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;