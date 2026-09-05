# Changelog

All notable changes to this project are documented here. Releases follow
[Semantic Versioning](https://semver.org/).

## [1.3.0] - 2026-09-05

### Added

- A 49-position tray and fit-test coupon for MPE M-PLCC 32 T through-hole
  sockets, compatible with the existing stacking interface and lid.
- A fit-test-corrected 6 × 8 × 4 mm PLCC32 support island that fits inside
  the socket's bent pins.
- PLCC32 pocket walls raised by 5 mm so their tops are approximately flush
  with the socket body.
- A populated PLCC32 tray preview rendered with the same Blender workflow as
  the existing DIP tray previews.

## [1.2.0] - 2026-09-02

### Added

- Universal lid with the same underside groove and top stacking lip as the
  trays, allowing it to cap a stack or sit between trays.
- Automatic lid STL generation in the build and release bundles.

## [1.1.0] - 2026-08-31

### Changed

- Extended both outer channel guides to meet the perimeter wall, eliminating
  the narrow gaps without changing socket clearance or tray capacity.
- Increased the label size and centered it vertically from the calculated
  wall height.

## [1.0.0] - 2026-08-31

### Added

- Parametric trays for DIP-14, DIP-16, DIP-18, DIP-20, DIP-28, DIP-32, and
  DIP-40 sockets.
- Common stackable tray interface, recessed label inlays, and fit-test
  coupons.
- Retaining guides on both sides of every storage channel, including the two
  channels next to the tray perimeter.
- Versioned release automation with a complete STL archive and SHA-256
  checksums.

[1.3.0]: https://github.com/ifilot/parametric-dip-socket-tray/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ifilot/parametric-dip-socket-tray/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ifilot/parametric-dip-socket-tray/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ifilot/parametric-dip-socket-tray/releases/tag/v1.0.0
