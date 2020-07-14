# Ruby Analytics for Snowplow

[![early-release]][tracker-classificiation]
[![Gem Version](https://badge.fury.io/rb/snowplow-tracker.svg)](https://badge.fury.io/rb/snowplow-tracker)
[![Build Status](https://travis-ci.org/snowplow/snowplow-ruby-tracker.png?branch=master)](https://travis-ci.org/snowplow/snowplow-ruby-tracker)
[![Code Climate](https://codeclimate.com/github/snowplow/snowplow-ruby-tracker.png)](https://codeclimate.com/github/snowplow/snowplow-ruby-tracker)
[![Coverage Status](https://coveralls.io/repos/snowplow/snowplow-ruby-tracker/badge.png)](https://coveralls.io/r/snowplow/snowplow-ruby-tracker)
[![License][license-image]][license]

## Overview

Add analytics to your Ruby and Rails apps and gems with the **[Snowplow][snowplow]** event tracker for **[Ruby][ruby]**.

With this tracker you can collect event data from your **[Ruby][ruby]** applications, **[Ruby on Rails][rails]** web applications and **[Ruby gems][rubygems]**.

## Quickstart

Assuming git, **[Vagrant][vagrant-install]** and **[VirtualBox][virtualbox-install]** installed:

```bash
 host$ git clone https://github.com/snowplow/snowplow-ruby-tracker.git
 host$ cd snowplow-ruby-tracker
 host$ vagrant up && vagrant ssh
guest$ cd /vagrant
guest$ gem install bundler
guest$ bundle install
guest$ rspec
```

## Publishing

```bash
 host$ vagrant push
```

## Find out more

| Technical Docs                  | Setup Guide               | Roadmap                 | Contributing                      |
|---------------------------------|---------------------------|-------------------------|-----------------------------------|
| ![i1][techdocs-image]          | ![i2][setup-image]       | ![i3][roadmap-image]   | ![i4][contributing-image]        |
| **[Technical Docs][techdocs]** | **[Setup Guide][setup]** | **[Roadmap][roadmap]** | **[Contributing](Contributing.md)** |

## Copyright and license

The Snowplow Ruby Tracker is copyright 2013-2016 Snowplow Analytics Ltd.

Licensed under the **[Apache License, Version 2.0][license]** (the "License");
you may not use this software except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[license-image]: https://img.shields.io/badge/license-Apache--2-blue.svg?style=flat
[license]: https://www.apache.org/licenses/LICENSE-2.0

[ruby]: https://www.ruby-lang.org/en/
[rails]: https://rubyonrails.org/
[rubygems]: https://rubygems.org/

[snowplow]: httpd://snowplowanalytics.com

[vagrant-install]: https://docs.vagrantup.com/v2/installation
[virtualbox-install]: https://www.virtualbox.org/wiki/Downloads

[techdocs-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/techdocs.png
[setup-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/setup.png
[roadmap-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/roadmap.png
[contributing-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/contributing.png

[techdocs]: https://github.com/snowplow/snowplow/wiki/Ruby-Tracker
[setup]: https://github.com/snowplow/snowplow/wiki/Ruby-Tracker-Setup
[roadmap]: https://github.com/snowplow/snowplow/wiki/Ruby-Tracker-Roadmap

[tracker-classificiation]: https://github.com/snowplow/snowplow/wiki/Tracker-Maintenance-Classification
[early-release]: https://img.shields.io/static/v1?style=flat&label=Snowplow&message=Early%20Release&color=014477&labelColor=9ba0aa&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAeFBMVEVMaXGXANeYANeXANZbAJmXANeUANSQAM+XANeMAMpaAJhZAJeZANiXANaXANaOAM2WANVnAKWXANZ9ALtmAKVaAJmXANZaAJlXAJZdAJxaAJlZAJdbAJlbAJmQAM+UANKZANhhAJ+EAL+BAL9oAKZnAKVjAKF1ALNBd8J1AAAAKHRSTlMAa1hWXyteBTQJIEwRgUh2JjJon21wcBgNfmc+JlOBQjwezWF2l5dXzkW3/wAAAHpJREFUeNokhQOCA1EAxTL85hi7dXv/E5YPCYBq5DeN4pcqV1XbtW/xTVMIMAZE0cBHEaZhBmIQwCFofeprPUHqjmD/+7peztd62dWQRkvrQayXkn01f/gWp2CrxfjY7rcZ5V7DEMDQgmEozFpZqLUYDsNwOqbnMLwPAJEwCopZxKttAAAAAElFTkSuQmCC
