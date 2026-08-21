#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
install_script = (root / 'script' / 'install.sh').read_text()
package_script = (root / 'script' / 'package.sh').read_text()
enable_script = (root / 'script' / 'enable_akshara.swift').read_text()

assert 'version_at_least' in install_script, 'install.sh should define a version gate helper'
assert '0.1.21' in install_script, 'install.sh should include the cleanup migration threshold'
assert 'cleanup_akshara_sources.swift' in install_script, 'install.sh should trigger stale input-source cleanup'
assert 'USER_APP_NAME="Akshara.app"' in package_script, 'package.sh should remove the per-user duplicate bundle'
assert 'launchctl asuser' in package_script, 'package.sh should clean the logged-in user preferences'
assert 'AppleEnabledInputSources' in package_script, 'package.sh should clean enabled input-source entries'
assert '"$LSREGISTER" -u "$DST"' in install_script, 'install.sh should unregister the canonical user bundle before replacement'
assert '"$LSREGISTER" -f "$DST"' in install_script, 'install.sh should register only the canonical user bundle'
assert '"$LSREGISTER" -f "$APP"' in package_script, 'package.sh should register only the canonical system bundle'
assert 'sourceID.hasPrefix(bundleID + ".")' in enable_script, 'registration should recognize component input-source IDs'
assert '!hasRegisteredInputSource(for: bundleID)' in enable_script, 'registration should be idempotent'

print('migration gate checks passed')
