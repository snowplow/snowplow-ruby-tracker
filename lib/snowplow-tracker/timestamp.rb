# Copyright (c) 2016 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Alex Dean, Fred Blundun, Ed Lewis (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2016 Snowplow Analytics Ltd
# License:: Apache License Version 2.0

module SnowplowTracker
  class Timestamp
    attr_reader :type
    attr_reader :value

    def initialize(type, value)
      @type = type
      @value = value
    end

    def self.create
      (Time.now.to_f * 1000).to_i
    end
  end

  class TrueTimestamp < Timestamp
    def initialize(value)
      super 'ttm', value
    end
  end

  class DeviceTimestamp < Timestamp
    def initialize(value)
      super 'dtm', value
    end
  end
end
