require 'base64'
require 'json'
require 'net/http'

module Snowplow

	class Payload
		attr_reader :context
		def initialize
			@context = {}
			@context['test'] = 9
		end

		def add(name, value)
			if not value == "" and not value.nil?
				@context[name] = value
			end
		end

		def add_dict(dict)
			for f in dict
				self.add(f[0], f[1])
			end
		end

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

