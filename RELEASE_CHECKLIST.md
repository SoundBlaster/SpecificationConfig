# Release Checklist

Use this checklist to prepare a 0.1.x release of SpecificationConfig.

## Preflight

- [ ] Confirm a clean working tree: `git status --porcelain`
- [ ] Run CI-equivalent checks:
  - [ ] `swift build -v`
  - [ ] `swift test -v`
  - [ ] `swiftformat --lint .`

## Documentation

- [ ] Update `CHANGELOG.md` with the release date and summary
- [ ] Verify `README.md` quickstart and demo steps
- [ ] Verify tutorials under `Sources/SpecificationConfig/Documentation.docc/Tutorials/`

## Release

- [ ] Create an annotated tag: `git tag -a 0.1.0 -m "0.1.0"`
- [ ] Push tag: `git push --tags`
- [ ] Create a GitHub Release for the tag and paste changelog notes

## Post-Release

- [ ] Announce the release and link to the changelog entry
