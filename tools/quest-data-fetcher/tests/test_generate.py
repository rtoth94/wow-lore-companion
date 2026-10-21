import json
import io
from contextlib import redirect_stdout
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

from quest_data_fetcher.generate import generate, lua
from quest_data_fetcher.api import ResourceNotFound
from manage import package


class GenerationTests(unittest.TestCase):
    def test_missing_resource_preserves_id_without_blocking_generation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / 'map.json'
            path.write_text(json.dumps({'campaign_id': 270, 'chapters': [
                {'chapter_id': 5726, 'title': 'Test chapter', 'quest_ids': [10, 86874]},
            ]}))
            output = root / 'output'
            with patch('quest_data_fetcher.generate.authenticate', return_value='test-token'), \
                 patch('quest_data_fetcher.generate.time.sleep'), \
                 patch('quest_data_fetcher.generate.fetch_quest', side_effect=[
                     {'id': 10, 'description': 'Test description'}, ResourceNotFound('HTTP 404')]):
                generate(path, output, 'eu', root / '.env')
            report = json.loads((output / 'manifest.json').read_text())
            self.assertEqual(report['results'][1]['status'], 'unavailable')
            text = (output / 'QuestData.lua').read_text()
            self.assertIn('{ 10, 86874 }', text)
            self.assertIn('[86874] = {\n["descriptionAvailable"] = false,\n}', text)
            self.assertIn('Test description', text)
            self.assertFalse((output / 'quest-86874.json').exists())

    def test_full_campaign_generation_and_package(self):
        project = Path(__file__).resolve().parents[1]
        map_path = project / 'quest_map.json'
        mapping = json.loads(map_path.read_text(encoding='utf-8'))
        chapters = mapping['chapters']
        self.assertEqual(len(chapters), 17)
        quest_ids = [quest_id for chapter in chapters for quest_id in chapter['quest_ids']]
        self.assertEqual(len(quest_ids), 233)
        unique_ids = list(dict.fromkeys(quest_ids))

        # Synthetic API responses exercise packaging without credentials or lore fixtures.
        def response(quest_id, region, token):
            return {'id': quest_id, 'title': f'Test quest {quest_id}',
                    'description': f'Test description {quest_id}'}

        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            output = Path(tmp)
            with patch('quest_data_fetcher.generate.authenticate', return_value='test-token'), \
                 patch('quest_data_fetcher.generate.time.sleep'), \
                 patch('quest_data_fetcher.generate.fetch_quest', side_effect=response) as fetch:
                generate(map_path, output, 'eu', output / '.env')
            self.assertEqual([call.args[0] for call in fetch.call_args_list], unique_ids)
            report = json.loads((output / 'manifest.json').read_text(encoding='utf-8'))
            self.assertEqual(report['map'], mapping)
            self.assertEqual(len(report['results']), len(unique_ids))
            generated = (output / 'QuestData.lua').read_text(encoding='utf-8')
            for chapter in chapters:
                self.assertIn(lua({'chapterID': chapter['chapter_id'], 'title': chapter['title'],
                                   'questIDs': chapter['quest_ids']}), generated)
            for quest_id in unique_ids:
                self.assertIn(f'Test description {quest_id}', generated)
            archive_path = package(output, project.parents[1] / 'LoreCompanion')
            with ZipFile(archive_path) as archive:
                self.assertEqual(archive.read('LoreCompanion/QuestData.lua').decode('utf-8'), generated)
                toc = archive.read('LoreCompanion/LoreCompanion.toc').decode('utf-8')
                self.assertLess(toc.index('QuestData.lua'), toc.index('Campaign.lua'))

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
