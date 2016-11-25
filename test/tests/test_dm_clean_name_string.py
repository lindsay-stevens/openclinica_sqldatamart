from unittest import TestCase
import psycopg2
from tests import configs


class TestCleanNameString(TestCase):
    """Tests for openclinica_fdw.dm_clean_name_string"""
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
        self.sql = "SELECT openclinica_fdw.dm_clean_name_string(%s)"

    def tearDown(self):
        self.cursor.close()

    def test_valid_string_unchanged(self):
        """Should not change a valid string."""
        test_input = ("this_string_here",)
        expected = ("this_string_here",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_lower_case_characters(self):
        """Should convert characters to lowercase."""
        test_input = ("THIS STRING HERE",)
        expected = ("this_string_here",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_unicode_escape_invalid_identifier_characters(self):
        """Should unicode escape invalid chars."""
        test_input = ("this/string -Here",)
        expected = ("this_u2f_string__u2d_here",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_unicode_escape_invalid_identifier_characters_high_utf8(self):
        """Should unicode escape invalid chars, even weird ones."""
        test_input = ("yay 😊 a happy smiley face",)
        expected = ("yay__u1f60a__a_happy_smiley_face",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_whitespace_not_shrunk(self):
        """Should not collapse consecutive whitespaces, just replace them."""
        test_input = ("strange                    text",)
        expected = ("strange____________________text",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

    def test_whitespace_non_space_to_escape(self):
        """Should perform unicode escape on whitespace that isn't a space."""
        test_input = ("first\r\nsecond\twith a tab",)
        expected = ("first_ud__ua_second_u9_with_a_tab",)
        self.cursor.execute(self.sql, test_input)
        observed = self.cursor.fetchone()
        self.assertEqual(observed, expected)

