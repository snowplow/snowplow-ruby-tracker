# Copyright (c) 2013 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author::    Alex Dean (mailto:snowplow-user@googlegroups.com)
# Copyright:: Copyright (c) 2013 Snowplow Analytics Ltd
# License::   Apache License Version 2.0

require 'contracts'
include Contracts

module Snowplow

  # A user. Typically used as the Subject of events;
  # sometimes as the Object.
  # Inherits from Entity.
  class User < Entity

    attr_reader :ip_address,
                :business_user_id,
                :domain_user_id,
                :network_user_id

    # Constructor for a new User.
    # All fields are individually optional
    # but at least one must be set
    #
    # Parameters:
    # +ip_address+:: user's IP address
    # +business_user_id+:: user's business-defined ID
    # +domain_user_id+:: user's ID stored by Snowplow
    #                    on a first-party cookie
    # +network_user_id+:: user's ID stored by Snowplow
    #                     on a third-party cookie
    Contract OptionString,
             OptionString,
             OptionString,
             OptionString => nil
    def initialize(ip_address=nil,
                   business_user_id=nil,
                   domain_user_id=nil,
                   network_user_id=nil)

      # TODO: add validation that at least one arg set

      @ip_address = ip_address
      @business_user_id = business_user_id
      @domain_user_id = domain_user_id
      @network_user_id = network_user_id
      nil
    end

    # Converts this Subject into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def as_hash()
      to_protocol(
        [ 'ip',  @ip_address, :raw ],
        [ 'uid',  @business_user_id ],
        [ 'duid',  @domain_user_id, :raw ],
        [ 'nuid',  @network_user_id, :raw ]
      )
    end

  end

end
