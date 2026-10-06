# Icon masters

The Akshara icon shared with the Android and iOS apps. `script/generate_icons.swift` builds the macOS
icons in `support/Resources` from these files:

- `AksharaIcon-1024.png`: the full-colour icon (from akshara-ios `AppIcon.appiconset/Icon-1024.png`).
  Becomes `Akshara.icns` and `AksharaIconMaster.png` on the macOS icon grid.
- `AksharaMonochrome.png`: the one-colour mark (from akshara-android
  `drawable-nodpi/ic_launcher_monochrome.png`). Becomes the input-menu template icons
  `AksharaMenu*.tif` / `AksharaMenuWhite*.tif`.

These files are not copied into the app bundle.
