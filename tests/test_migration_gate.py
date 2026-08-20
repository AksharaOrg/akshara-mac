#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
install_script = (root / 'script' / 'install.sh').read_text()

assert 'version_at_least' in install_script, 'install.sh should define a version gate helper'
assert '0.1.22' in install_script, 'install.sh should include the cleanup migration threshold'
assert 'cleanup_akshara_sources.swift' in install_script, 'install.sh should trigger stale input-source cleanup'

print('migration gate checks passed')
