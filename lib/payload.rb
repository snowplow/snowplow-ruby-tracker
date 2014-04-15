# Copyright (c) 2013-2014 SnowPlow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Alex Dean, Fred Blundun (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2013-2014 SnowPlow Analytics Ltd
# License:: Apache License Version 2.0

require 'base64'
require 'json'
require 'net/http'
require 'contracts'
include Contracts

module Snowplow

  class Payload

    attr_reader :context

    def initialize
      @context = {}
    end

    Contract String, Or[String, Bool, Num, nil] => Or[String, Bool, Num, nil]
    def add(name, value)
      if not value == "" and not value.nil?
        @context[name] = value
      end
    end

    Contract Hash => Hash
    def add_dict(dict)
      for f in dict
        self.add(f[0], f[1])
      end
    end

    Contract Or[Hash, nil], Bool, String, String => Or[String, nil]
    def add_json(dict, encode_base64, type_when_encoded, type_when_not_encoded)
      if dict.nil?
        return
      end

      dict_string = JSON.generate(dict)

      if encode_base64
        self.add(type_when_encoded, Base64.encode64(dict_string))
      else
        self.add(type_when_not_encoded, dict_string)
      end
    end
  end
end

