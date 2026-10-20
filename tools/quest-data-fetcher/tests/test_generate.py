import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from quest_data_fetcher.generate import generate, lua


class GenerationTests(unittest.TestCase):
    def test_lua_escaping(self):
        self.assertEqual(lua('"\\\n\x001é'), '"\\"\\\\\\010\\0001é"')

    def test_shared_quest_preserves_chapter_lists(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mapping = {'campaign_id': 270, 'chapters': [
                {'chapter_id': 1, 'title': 'One', 'quest_ids': [10, 20]},
                {'chapter_id': 2, 'title': 'Two', 'quest_ids': [20]},
            ]}
            path = root / 'map.json'
            path.write_text(json.dumps(mapping))
            output = root / 'output'
            output.mkdir()
            (output / 'README.md').write_text('keep')
            with patch('quest_data_fetcher.generate.authenticate', return_value='secret'), patch('quest_data_fetcher.generate.time.sleep'), patch('quest_data_fetcher.generate.fetch_quest', side_effect=[{'id': 10, 'description': 'Original\n\né'}, {'id': 20}]) as fetch:
                generate(path, output, 'eu', root / '.env')
            self.assertEqual(fetch.call_count, 2)
            self.assertEqual((output / 'README.md').read_text(), 'keep')
            text = (output / 'QuestData.lua').read_text()
            self.assertIn('{ 10, 20 }', text)
            self.assertIn('{ 20 }', text)
            self.assertIn('["descriptionAvailable"] = false', text)
            self.assertNotIn('secret', text)
            with patch('quest_data_fetcher.generate.authenticate', return_value='secret'), patch('quest_data_fetcher.generate.time.sleep'), patch('quest_data_fetcher.generate.fetch_quest', side_effect=RuntimeError('HTTP 404')):
                with self.assertRaises(RuntimeError):
                    generate(path, output, 'eu', root / '.env')
            self.assertFalse((output / 'QuestData.lua').exists())
            self.assertEqual(json.loads((output / 'manifest.json').read_text())['results'][0]['status'], 'failed')


if __name__ == '__main__':
    unittest.main()
