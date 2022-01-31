# iOSClientSDKSampleApp

Example application for developers to follow how to use EMP iOS SDKs

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Exposure Playback

* [Features](#features)
* [License](https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp/blob/master/LICENSE)
* [Requirements](#requirements)
* [Installation](#installation)
* [Release Notes](#release-notes)

## Features

- [x] Authentication
- [x] Asset search
- [x] EPG discovery
- [x] Live Event discovery
- [x] Vod, Live and Catchup playback.
- [x] Download and offline playback.
- [x] ChromeCast integration


## Requirements

* `iOS` 11.0+
* `Swift` 5.0+
* `Xcode` 12.0+

* Framework dependencies
    - [`Exposure`](https://github.com/EricssonBroadcastServices/iOSClientExposure)
    - [`Player`](https://github.com/EricssonBroadcastServices/iOSClientPlayer)
    - [`ExposurePlayback`](https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback)
    - [`Download`](https://github.com/EricssonBroadcastServices/iOSClientDownload)
    - [`ExposureDownload`](https://github.com/EricssonBroadcastServices/iOSClientExposureDownload)
    - [`Cast`](https://github.com/EricssonBroadcastServices/iOSClientCast)
    - Exact versions described in [Cartfile](https://github.com/EricssonBroadcastServices/iOSClientRefApp/blob/master/Cartfile)

## Installation

Installation can be done by cloning the repo  *iOSClientSDKSampleApp* & run `carthage update --use-submodules --use-xcframeworks`


### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependency graph without interfering with your `Xcode` project setup. `CI` integration through [fastlane](https://github.com/fastlane/fastlane) is also available.

Install *Carthage* through [Homebrew](https://brew.sh) by performing the following commands:

```sh
$ brew update
$ brew install carthage
```

Updating your dependencies is done by running  `carthage update` with the relevant *options*, such as `--use-submodules`, depending on your project setup. For more information regarding dependency management with `Carthage` please consult their [documentation](https://github.com/Carthage/Carthage/blob/master/README.md) or run `carthage help`.


Running `carthage update` will fetch your dependencies and place them in `/Carthage/Checkouts`. You either build the `.framework`s and drag them in your `Xcode` or attach the fetched projects to your `Xcode workspace`.

Finally, make sure you add the `.framework`s to your targets *General -> Embedded Binaries* section.

## Release Notes
Release specific changes can be found in the [CHANGELOG](https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp/blob/master/CHANGELOG.md).





