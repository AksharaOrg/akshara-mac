# Akshara for macOS

A clean-room Sinhala input method for modern macOS. It provides three input modes:

- `Akshara - Phonetic`: romanized Sinhala composition.
- `Akshara - Smart Phonetic`: advanced phonetic typing with simplified combinations (e.g., 'Aa' for 'ඈ', 'x' for 'ං').
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

## GitHub releases

Pushing a tag such as `v0.1.0` runs the signed-release workflow. It uses the
protected `release` environment and requires these GitHub Actions
secrets:

- `MACOS_APP_SIGNING_CERTIFICATE_BASE64`: a password-protected `.p12` export
  of the Developer ID Application certificate and private key, Base64 encoded.
- `MACOS_INSTALLER_SIGNING_CERTIFICATE_BASE64`: the equivalent Developer ID
  Installer `.p12` export.
- `MACOS_CERTIFICATE_PASSWORD`: the password used for both `.p12` exports.
- `APPLE_NOTARY_API_KEY_BASE64`: a Base64-encoded App Store Connect API-key
  `.p8` file with access to notarization.
- `APPLE_NOTARY_KEY_ID` and `APPLE_NOTARY_ISSUER_ID`: the matching API-key
  identifiers.

The workflow signs the app and installer, notarizes and staples the package,
then publishes it as a GitHub Release asset. Keep the GitHub environment
restricted to trusted release approvers; never commit any of these values.

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

## Smart Phonetic Typing Rules

Smart Phonetic introduces an intuitive set of rules to type Sinhala quickly using English letters:

### Vowels
- **අ** (`a`), **ආ** (`aa`), **ඇ** (`A`), **ඈ** (`Aa` or `AA`)
- **ඉ** (`i`), **ඊ** (`ii`), **උ** (`u`), **ඌ** (`uu`)
- **ඍ** (`R`), **ඎ** (`Ru`)
- **එ** (`e`), **ඒ** (`ee`), **ඓ** (`ai`)
- **ඔ** (`o`), **ඕ** (`oo`), **ඖ** (`au` or `ou`)

### Consonants
- **ක** (`ka`), **ග** (`ga`), **ච** (`cha`), **ජ** (`ja`)
- **ට** (`ta`), **ඩ** (`da`), **ත** (`tha`), **ද** (`dha` or `q`)
- **න** (`na`), **ණ** (`N`), **ප** (`pa`), **බ** (`ba`), **ම** (`ma`)
- **ය** (`ya`), **ර** (`ra`), **ල** (`la`), **ළ** (`L`), **ව** (`w` or `v`)
- **ස** (`sa`), **ශ** (`sha`), **ෂ** (`Sa` or `Sha`)
- **හ** (`ha`), **ෆ** (`fa`), **ඞ** (`X`)

### Mahaprana (Aspirated) Consonants
- **ඛ** (`kha`), **ඝ** (`gha`), **ඡ** (`chha`)
- **ඨ** (`Ta`), **ඪ** (`Da`), **ථ** (`thha`), **ධ** (`dhha`)
- **ඵ** (`pha`), **භ** (`bha`)

### Sanyaka Consonants
- **ඟ** (`zga`), **ඦ** (`zja`), **ඬ** (`zd`a)
- **ඳ** (`zdha` or `zqa`), **ඤ** (`zka`), **ඥ** (`zha`), **ඹ** (`Ba`)

### Special Symbols
- **Anusvara (ං)**: `x`, or `M`
- **Visarga (ඃ)**: `H`
- **Double Space**: Pressing space twice will natively insert a full stop (period) across all modes.

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
