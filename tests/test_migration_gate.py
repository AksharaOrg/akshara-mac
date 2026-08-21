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
assert '"$LSREGISTER" -f "$DST"' not in install_script, 'install.sh must not explicitly register the user bundle'
assert 'enable_akshara.swift" "$DST"' not in install_script, 'install.sh must not explicitly register TIS sources'
assert '"$LSREGISTER" -f "$APP"' not in package_script, 'package.sh must not explicitly register the package bundle'
assert '"$LSR" -u "$PKG_ROOT"' in package_script, 'package.sh should unregister the generated package root'
assert '"$LSR" -u "$APP"' in package_script, 'package.sh should unregister the generated dist app'
assert 'sudo rm -rf "$SYSTEM_DST"' in install_script, 'install.sh should remove a system install before creating a user install'
assert 'rm -rf "$SRC"' in install_script, 'install.sh should remove the generated app after copying it into Input Methods'
assert 'rm -rf "$APP"' in package_script, 'package.sh should remove the generated app after packaging'
assert 'sourceID.hasPrefix(bundleID + ".")' in enable_script, 'registration should recognize component input-source IDs'
assert '!hasRegisteredInputSource(for: bundleID)' in enable_script, 'registration should be idempotent'

print('migration gate checks passed')
