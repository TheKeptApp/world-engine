"""The common survey downloader retries transient failures, never permanent ones."""
import io
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'terrain'))
import slope


class SurveyFetchRetry(unittest.TestCase):
    def test_transient_503_then_success_is_ledgered_once(self):
        work = Mock()
        with patch.object(slope.urllib.request, 'urlopen', side_effect=[HTTPError('https://example.invalid',503,'busy',{},None), io.BytesIO(b'point-data')]) as request, patch.object(slope.time, 'sleep'):
            self.assertEqual(slope.http('https://example.invalid',work,'area','ept-data'), b'point-data')
        self.assertEqual(request.call_count,2)
        work.ledger_add.assert_called_once_with('area','ept-data','https://example.invalid',10)

    def test_404_fails_without_retry_or_ledger(self):
        work = Mock()
        with patch.object(slope.urllib.request, 'urlopen', side_effect=HTTPError('https://example.invalid',404,'missing',{},None)) as request, patch.object(slope.time,'sleep') as sleep:
            with self.assertRaises(HTTPError): slope.http('https://example.invalid',work,'area','ept-data')
        self.assertEqual(request.call_count,1);sleep.assert_not_called();work.ledger_add.assert_not_called()

    def test_persistent_503_is_bounded_to_four_attempts(self):
        work = Mock()
        with patch.object(slope.urllib.request, 'urlopen', side_effect=HTTPError('https://example.invalid',503,'busy',{},None)) as request, patch.object(slope.time,'sleep'):
            with self.assertRaises(HTTPError): slope.http('https://example.invalid',work,'area','ept-data')
        self.assertEqual(request.call_count,4);work.ledger_add.assert_not_called()
