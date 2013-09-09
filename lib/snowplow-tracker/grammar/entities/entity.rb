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

module Snowplow

  # Parent class for any entity which is the Subject
  # or Object (Direct, Indirect, Prepositional) of a
  # Snowplow event, or potentially (in the case of
  # WebPage) part of the Context.
  #
  # Mixes in GrammarElement, as all entities must be
  # convertable to Snowplow Tracker Protocol.
  class Entity

  	include GrammarElement

  end

end