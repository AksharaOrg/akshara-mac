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

uninstall_script = (root / 'script' / 'uninstall.sh').read_text()
build_script = (root / 'script' / 'build_and_run.sh').read_text()
assert '$HOME/Applications/$LAUNCHER_NAME' in install_script, 'install.sh should install Akshara Settings to ~/Applications'
assert '$PKG_ROOT/Applications/$LAUNCHER_NAME.app' in package_script, 'package.sh should stage Akshara Settings in /Applications'
assert 'Akshara Settings.app' in uninstall_script, 'uninstall.sh should remove Akshara Settings'
assert 'open -n' not in package_script + build_script, 'launching with open -n starts a second input method process'

# A window the app keeps a reference to must not also be released by AppKit when it closes: that
# over-release crashed Akshara when Welcome or a typing guide was closed.
for source in (root / 'src').glob('*.swift'):
    text = source.read_text()
    assert text.count('NSWindow(') <= text.count('isReleasedWhenClosed = false'), \
        f'{source.name}: set isReleasedWhenClosed = false on every NSWindow it creates'

# Fresh installs: the input method registers itself (only from an Input Methods folder), and the
# package scripts don't need the developer tools (/usr/bin/swift is a stub without them).
main_source = (root / 'src' / 'main.m').read_text()
release_script = (root / 'script' / 'release.sh').read_text()
assert 'TISRegisterInputSource' in main_source and '@"Input Methods"' in main_source, \
    'main.m should register its input sources when it runs from an Input Methods folder'
assert 'swift "$DIALOG_SOURCE"' not in package_script, 'the restart prompt must not need /usr/bin/swift'
assert 'xcode-select -p' in package_script, 'package.sh should run swift only when the developer tools are installed'
assert '$PKG_SCRIPTS/preinstall' in package_script, 'package.sh should tell an update from a fresh install'
assert 'upstream/main' in release_script, 'release.sh should only tag upstream/main'

print('migration gate checks passed')
