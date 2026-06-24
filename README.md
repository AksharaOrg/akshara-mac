# Akshara for macOS

A clean-room Sinhala input method for modern macOS. It provides two input modes:

- `Akshara - Phonetic`: romanized Sinhala composition.
- `Akshara - SLS1134`: direct Wijesekara/SLS-style key entry.

## Requirements

- macOS 12 or later
- Xcode command line tools
- Apple Developer ID certificates only for signed release packages

## Build

```sh
./script/build_and_run.sh
```

The built app is staged at `dist/Akshara.app`.

## Install

```sh
./script/install.sh
```

Then log out and back in, or restart the Text Input system:

```sh
killall TextInputMenuAgent
```

Open System Settings, add an input source for Sinhala, and select one of the
`Akshara` modes.

## Package

Build a distributable installer package:

```sh
./script/package.sh
```

The package is written to `dist/Akshara-0.1.0.pkg`. It installs Akshara to
`/Library/Input Methods/Akshara.app`, registers the bundle with macOS, and
restarts Text Input services. After installation, add `Akshara - Wijesekara` or
`Akshara - Phonetic` from System Settings > Keyboard > Input Sources.

The local package is ad-hoc signed for development. For public distribution,
sign the app with a Developer ID Application certificate, sign the package with
a Developer ID Installer certificate, notarize it with Apple, and staple the
notarization ticket.

Release signing is supported with environment variables:

```sh
AKSHARA_APP_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
AKSHARA_PKG_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
AKSHARA_NOTARY_PROFILE="notarytool-profile-name" \
./script/package.sh
```

Omit `AKSHARA_NOTARY_PROFILE` to build a signed package without notarizing.

## License

Akshara is released under the [MIT License](https://opensource.org/license/mit).
See [LICENSE](LICENSE).

## Phonetic Examples

- `amma` -> `අම්ම`
- `mama` -> `මම`
- `sri` -> `ස්රි`
- `siMhala` -> `සිංහල`
- `aa`, `ae`, `ii`, `uu`, `ee`, `ai`, `oo`, `au` produce long or compound vowels.

Use `M` for anusvara (`ං`) and `H` for visarga (`ඃ`).

## Wijesekara/SLS Ordering

The SLS1134 mode accepts the visual Wijesekara order for kombuva sequences and
stores them in Unicode order. For example:

- `ෙ + ක + ා` -> `කො`
- `ෙ + ක + ා + ්` -> `කෝ`
- `ෙ + ක + ්` -> `කේ`
- `ෙ + ක + ෟ` -> `කෞ`
- `ෙ + ෙ + ක` -> `කෛ`
- `ෙ + ෙ + ක + ෙ` -> `කෛ` plus a pending kombuwa for the next syllable
- `අ + ැ` -> `ඇ`
- `අ + ා` -> `ආ`

The SLS mode also supports the public Wijesekara/SLS control symbols for
yansaya, rakaransaya, repaya, join/touching letters, sanyakaya forms, visargaya,
kunddaliya, non-breaking/invisible spaces, and common AltGr entries.
