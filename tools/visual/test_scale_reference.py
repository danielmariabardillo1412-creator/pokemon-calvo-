import json
import unittest

from build_showdown_scale_reference import parse_metadata


class MetadataParserTests(unittest.TestCase):
    def fixture(self):
        return "\n".join(f"test{i}:{{num:{i},front:{{w:45,h:49}},back:{{w:52,h:50}}}}," for i in range(1000))

    def test_data_only_parser(self):
        rows = parse_metadata(self.fixture())
        self.assertEqual(len(rows), 1000)
        self.assertEqual(rows["test321"]["front"], {"w": 45, "h": 49})

    def test_incomplete_snapshot_rejected(self):
        with self.assertRaises(ValueError):
            parse_metadata("wailord:{num:321,front:{w:146,h:81}},")

    def test_executable_value_is_not_evaluated(self):
        with self.assertRaises(json.JSONDecodeError):
            parse_metadata(self.fixture() + "\nbad:{num:1,front:evil()},")


if __name__ == "__main__":
    unittest.main()
