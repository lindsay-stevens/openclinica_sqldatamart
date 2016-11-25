from unittest import TestCase
import psycopg2
from decimal import Decimal
from tests import configs
from datetime import date


class TestCleanTryCastValue(TestCase):
    """Tests for openclinica_fdw.dm_clean_try_cast_value.

    Return signature: (data_text, data_numeric, data_date, cast_failure)
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
        self.sql = \
            """WITH test_data AS (SELECT *
                FROM (VALUES (%s, %s)) AS t(data_type_id_in, data_text_in))
               SELECT (openclinica_fdw.dm_clean_try_cast_value(
                         data_type_id_in, data_text_in)).* FROM test_data"""

    def tearDown(self):
        self.cursor.close()

    def test_whitespace_empty_to_null(self):
        """Should convert empty string to null."""
        test_input = (5, "",)
        expected = (None, None, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_whitespace_sequence_to_null(self):
        """Should convert string of whitespace only to null."""
        test_input = (5, "          ",)
        expected = (None, None, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_whitespace_preceding_text_loopback(self):
        """Should not nullify whitespace when followed by non-whitespace."""
        test_input = (5, "        my text",)
        expected = ("        my text", None, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_text_null_code_loopback(self):
        """Should not nullify null codes in text fields"""
        test_input = (5, "NPE",)
        expected = ("NPE", None, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_int_text_cast_failure(self):
        """Should return null for data_numeric and indicate cast failure."""
        test_input = (6, "NASK",)
        expected = ("NASK", None, None, True)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)
    
    def test_type_not_for_cast_loopback(self):
        """Should return value as text for data types not being cast."""
        test_input = (10, "2016-12",)  # 10 = PDATE
        expected = ("2016-12", None, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_int_to_numeric(self):
        """Should valid int string as numeric."""
        test_input = (6, "2016",)
        expected = ("2016", 2016, None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_real_to_numeric(self):
        """Should valid int string as numeric."""
        test_input = (6, "2016.6",)
        expected = ("2016.6", Decimal("2016.6"), None, False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_date_to_date(self):
        """Should valid date string as date."""
        test_input = (9, "2016-12-31",)
        expected = ("2016-12-31", None, date(2016, 12, 31), False)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)
