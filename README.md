# ELExport

[![Build Status](https://travis-ci.org/viktyz/ELExport.svg?branch=master)](https://travis-ci.org/viktyz/ELExport)
[![License](http://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)
[![Analytics](https://ga-beacon.appspot.com/UA-76943272-1/elexport/readme)](https://github.com/igrigorik/ga-beacon)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ELExport.svg)](https://img.shields.io/cocoapods/v/ELExport.svg)

`ELExport` is an easy and safe way to export log file. Using `ELog` instead of `NSLog` you can get more information from log file in disk.

## How To Get Started

- [Download ELExport](https://github.com/viktyz/ELExport.git) and try out the included iOS example project `ELog.xcodeproj`.
- Also you can try test cases in `ELogTests.m` to learn how to use the methods in `ELExport.h`.

## Communication

- If you'd like to **ask a general question**, send email to [66745628@qq.com](66745628@qq.com).
- If you **found a bug**, _and can provide steps to reliably reproduce it_, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like ELExport in your projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build ELExport 0.0.2.

#### Podfile

To integrate ELExport into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '7.0'

target 'TargetName' do
pod 'ELExport', '~> 0.0.2'
end
```

Then, run the following command:

```bash
$ pod install
```

## Architecture

- `ELELog`
- `ELEFile`
- `ELExport`

## Usage

After import `ELExport.h` in the code file where you want to export log to file in disk, just try to replace `NSLog` with `ELog`.
Then all the logs will saved to file in disk automaticly in the right time and safe way.

## License
```
The MIT License (MIT)

Copyright (c) 2016 Alfred Jiang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
