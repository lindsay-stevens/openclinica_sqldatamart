from unittest import TestCase
import psycopg2
from tests import configs


class TestSnapshotCodeStata(TestCase):
    """Tests for public.snapshot_code_stata.

    Call signature: (filter_study_name_schema,
      outputdir, odbc_string_or_file_dsn_path, data_filter_string)
    Return signature: setof text.
    """
    db = None

    @classmethod
    def setUpClass(cls):
        cls.db = psycopg2.connect(**configs.db_connection)

    @classmethod
    def tearDownClass(cls):
        cls.db.rollback()
        cls.db.close()

    def setUp(self):
        self.cursor = self.db.cursor()
        self.sql = "SELECT * FROM public.dm_snapshot_code_stata(%s, %s, %s, %s)"
        self.select_study = \
            """SELECT study_name_clean
               FROM dm.metadata_study
               WHERE study_id IN (
                 SELECT DISTINCT study_id FROM dm.study_ig_metadata)"""

    def tearDown(self):
        self.cursor.close()

    def test_first_3_rows_set_locals(self):
        """Should return set where first 3 rows set locals from input."""
        self.cursor.execute(self.select_study)
        study_name = self.cursor.fetchone()[0]
        test_input = (study_name, "out_dir", "dsn_string", "where true")
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchmany(3)
        for index in range(1, 2):
            self.assertIn(test_input[index], observed[index - 1][0])
            self.assertTrue(observed[index][0].startswith('local'))
