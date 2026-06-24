# Contributing

Thanks for improving Akshara.

## Development

Run the focused test suite before opening a pull request:

```sh
./script/test.sh
```

Build the input method bundle:

```sh
./script/build_and_run.sh build
```

Build a local installer package:

```sh
./script/package.sh
```

## Notes

- Keep generated files out of commits. `build/` and `dist/` are ignored.
- Keep SLS/Wijesekara behavior covered by tests in `tests/TestTransliterator.m`.
- Add lexicon-derived stress cases to `tests/SLSLexiconStress.tsv` when fixing parser regressions.
