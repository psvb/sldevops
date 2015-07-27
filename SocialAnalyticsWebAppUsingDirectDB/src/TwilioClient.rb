# Loading Ruby gems.
require 'twilio-ruby'

module Twilio
	class Client
		# Constructor function.
		def initialize(accountSid, authToken)
			@accountSid = accountSid
			@authToken = authToken
			@twilioClient = Twilio::REST::Client.new(@accountSid, @authToken)
		end

		def sendSMS(fromNumber, toNumber, message)
			begin
				message = @twilioClient.account.messages.create({
					:from => "#{fromNumber}", 
					:to => "#{toNumber}",
					:body => message
				})
			rescue Twilio::REST::RequestError => e
				return "#{e.message}"
			end

			return "success"
		end
	end
end