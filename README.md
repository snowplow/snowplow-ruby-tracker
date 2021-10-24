# Ruby Analytics for Snowplow

[![early-release]][tracker-classification]
[![Gem Version](https://badge.fury.io/rb/snowplow-tracker.svg)](https://badge.fury.io/rb/snowplow-tracker)
[![Build Status][gh-actions-image]][gh-actions]
[![Code Climate](https://codeclimate.com/github/snowplow/snowplow-ruby-tracker.png)](https://codeclimate.com/github/snowplow/snowplow-ruby-tracker)
[![Coverage Status](https://coveralls.io/repos/snowplow/snowplow-ruby-tracker/badge.png)](https://coveralls.io/r/snowplow/snowplow-ruby-tracker)
[![License][license-image]][license]

## Overview

Add analytics to your **[Ruby][ruby]** and **[Ruby on Rails][rails]** apps and **[gems][rubygems]** with the **[Snowplow][snowplow]** event tracker for **[Ruby][ruby]**.

Snowplow is a scalable open-source platform for rich, high quality, low-latency data collection. It is designed to collect high quality, complete behavioral data for enterprise business.

**To find out more, please check out the [Snowplow website][snowplow] and our [documentation][docs].**

## Quickstart

Add this gem to your Gemfile. It is compatible with Ruby versions 2.1 to 3.0+.

```ruby
gem "snowplow-tracker", "~> 0.7.0"
```

See our [demo app][demoapp] for an example of implementing the Ruby tracker in a Rails app.

## Find out more

| Technical Docs                 | API Docs                | Contributing                        |
| ------------------------------ | ----------------------- | ----------------------------------- |
| ![i1][techdocs-image]          | ![i1][techdocs-image]   | ![i4][contributing-image]           |
| **[Technical Docs][techdocs]** | **[API Docs][apidocs]** | **[Contributing](Contributing.md)** |

## Maintainer Quickstart

Clone this repo and navigate into the cloned folder. To run the tests locally, you will need [Docker][docker] installed.

```bash
docker build . -t ruby-tracker
docker run -v "$(pwd)":"/code" ruby-tracker
```

The `-v` flag for `docker run` creates a bind mount for the project directory. This means that changes to the files will be automatically applied within the Docker image. However, if you modify the `Gemfile` or `snowplow-tracker.gemspec` files, the image must be rebuilt.

Alternatively, test directly by installing Ruby 2.1+ and [Bundler][bundler]. Then run:

```bash
bundle install
rspec
```

To generate documentation using YARD, make sure the YARD and redcarpet gems are installed locally. Then run:
```bash
yard doc
```

## Contributing

Feedback and contributions are welcome - if you have identified a bug, please log an issue on this repo. For all other feedback, discussion or questions please open a thread on our [Discourse forum][discourse].

## Copyright and license

The Snowplow Ruby Tracker is copyright 2013-2021 Snowplow Analytics Ltd.

Licensed under the **[Apache License, Version 2.0][license]** (the "License");
you may not use this software except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[license-image]: https://img.shields.io/badge/license-Apache--2-blue.svg?style=flat
[license]: https://www.apache.org/licenses/LICENSE-2.0
[gh-actions]: https://github.com/snowplow/snowplow-ruby-tracker/actions
[gh-actions-image]: https://github.com/snowplow/snowplow-ruby-tracker/workflows/Test/badge.svg
[tracker-classification]: https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/tracker-maintenance-classification/
[early-release]: https://img.shields.io/static/v1?style=flat&label=Snowplow&message=Early%20Release&color=014477&labelColor=9ba0aa&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAeFBMVEVMaXGXANeYANeXANZbAJmXANeUANSQAM+XANeMAMpaAJhZAJeZANiXANaXANaOAM2WANVnAKWXANZ9ALtmAKVaAJmXANZaAJlXAJZdAJxaAJlZAJdbAJlbAJmQAM+UANKZANhhAJ+EAL+BAL9oAKZnAKVjAKF1ALNBd8J1AAAAKHRSTlMAa1hWXyteBTQJIEwRgUh2JjJon21wcBgNfmc+JlOBQjwezWF2l5dXzkW3/wAAAHpJREFUeNokhQOCA1EAxTL85hi7dXv/E5YPCYBq5DeN4pcqV1XbtW/xTVMIMAZE0cBHEaZhBmIQwCFofeprPUHqjmD/+7peztd62dWQRkvrQayXkn01f/gWp2CrxfjY7rcZ5V7DEMDQgmEozFpZqLUYDsNwOqbnMLwPAJEwCopZxKttAAAAAElFTkSuQmCC

[ruby]: https://www.ruby-lang.org/en/
[rails]: https://rubyonrails.org/
[rubygems]: https://rubygems.org/
[docker]: https://www.docker.com/
[bundler]: https://bundler.io/

[snowplow]: https://snowplowanalytics.com
[docs]: https://docs.snowplowanalytics.com/
[demoapp]: https://github.com/snowplow-incubator/snowplow-ruby-tracker-examples
[discourse]: https://discourse.snowplowanalytics.com

[techdocs-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/techdocs.png
[contributing-image]: https://d3i6fms1cm1j0i.cloudfront.net/github/images/contributing.png
[techdocs]: https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/ruby-tracker/
[apidocs]: https://snowplow.github.io/snowplow-ruby-tracker/
