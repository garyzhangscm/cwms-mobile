#!/usr/bin/env python3
"""Build a mobile artifact only after validating the external factory settings."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
from urllib.parse import urlsplit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--config', required=True, type=Path)
parser.add_argument('--flutter', default=shutil.which('flutter') or 'flutter')
parser.add_argument('target', choices=['apk', 'ipa', 'ios'])
parser.add_argument('build_args', nargs=argparse.REMAINDER)
args = parser.parse_args()
try:
    config = json.loads(args.config.read_text())
    for key in ['COLTON_API_URL', 'FAY_API_URL', 'LUGGAGE_API_URL']:
        value = config.get(key)
        if not isinstance(value, str):
            raise ValueError(f'{key} must be configured')
        url = urlsplit(value)
        if url.scheme not in ['http', 'https'] or not url.hostname or not value.endswith('/api/'):
            raise ValueError(f'{key} must be an HTTP(S) API URL ending in /api/')
    for key in ['INJECTION_COMPANY_CODE', 'LUGGAGE_COMPANY_CODE']:
        value = config.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f'{key} must be a nonempty company code')
    if any(a.startswith(('--dart-define', '-D')) for a in args.build_args):
        raise ValueError('Supply factory defines only through --config')
except (OSError, ValueError, AttributeError) as error:
    parser.error(str(error))
print('Factory URLs and company codes validated; passing settings into Flutter.', flush=True)
raise SystemExit(subprocess.call([
    args.flutter, 'build', args.target, *args.build_args,
    '--dart-define-from-file=' + str(args.config.resolve()),
], cwd=Path(__file__).resolve().parents[1]))
