# GCDOperations

[![GitHub release](https://img.shields.io/github/release/ffried/gcdoperations.svg?style=flat)](https://github.com/ffried/GCDOperations/releases/latest)
![Tests](https://github.com/ffried/GCDOperations/workflows/Tests/badge.svg)
[![Docs](https://img.shields.io/badge/-documentation-informational)](https://ffried.github.io/GCDOperations)

<!-- [![codecov](https://codecov.io/gh/ffried/GCDOperations/branch/main/graph/badge.svg)](https://codecov.io/gh/ffried/GCDOperations) -->

Operations written in Swift based purely on GCD - no Objective-C dynamics, no key value observing.

## Purpose

This project aims to provide Operations very similar to Foundation.Operation. However, instead of heavily relying on KVO and the like, this library implements it using purerly GCD features.
On top of that, this library embraces what Apple initially showed in in the ["Advanced Operations" WWDC Talk](https://developer.apple.com/videos/play/wwdc2015/226), and what was then continued to be developed and maintained by Pluralsight in [this repository](https://github.com/pluralsight/PSOperations).

## Documentation

You can find the online documentation of this project here:

-   [GCDCoreOperations](https://ffried.github.io/GCDOperations/main/documentation/gcdcoreoperations)
-   [GCDOperations](https://ffried.github.io/GCDOperations/main/documentation/gcdoperations).

## Credits

All features known from the WWDC Talk  [Advanced Operations](https://developer.apple.com/videos/play/wwdc2015/226) have only encountered slight adjustments.
So big thanks to Apple for the ideas and initial implementation of these features.
Also, thanks to pluralsight for adding tests and fixing some bugs [in their repository](https://github.com/pluralsight/PSOperations).

## License

See [LICENSE](./LICENSE) file.
