# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-17

### Added
- `StateBag.merge(**entries)` for bulk-setting multiple keys at once
- `StateBag.replace(hash)` for atomically replacing the entire state
- `StateBag.slice(*keys)` for extracting a hash of selected keys
- `StateBag.each(&block)` for iterating key-value pairs (returns an Enumerator without a block)

### Changed
- Issue templates now include Ruby code placeholders for reproduction and proposed-API fields

## [0.4.0] - 2026-04-15

### Added
- `StateBag.values` module method returning an Array of values from the current thread-local bag

## [0.3.0] - 2026-04-15

### Added
- `StateBag.size`, `StateBag.empty?`, and `StateBag.keys` introspection helpers

## [0.2.0] - 2026-04-04

### Added
- `fetch` method with default value and block support (raises KeyError when key missing)
- `delete` method for removing keys from state bag
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.7] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.6] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.5] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.1.4] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.3] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes

## [0.1.2] - 2026-03-22

### Changed
- Expanded test coverage to 30+ examples covering edge cases, error paths, and boundary conditions

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Thread-local key-value state storage with set and get
- Scoped overrides via with block with automatic restoration
- Clear, to_h, and key? utility methods
