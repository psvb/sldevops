require 'mail'

module SendGrid
	class Client
		# Constructor function.
		def initialize(hostName, userName, password)
			@hostName = hostName
			@userName = userName
			@password = password
		end

		def sendEmail(fromAddress, toAddress, subjectLine, message)
			sendgridOptions = {
				:address => "smtp.sendgrid.net",
				:port => 587,
				:domain => @hostName,
				:user_name => @userName,
				:password => @password,
				:authentication => 'plain',
				:enable_starttls_auto => true
			}

			begin
				Mail.defaults do
					delivery_method :smtp, sendgridOptions
				end            

				response = Mail.deliver do
					from "#{fromAddress}"
					to "#{toAddress}"
					subject "#{subjectLine}"

					text_part do
						body 'Message Details'
					end

					html_part do
						content_type 'text/html; charset=UTF-8'
						body "#{message}"
					end
				end
			rescue Exception => e
				puts e
				return "#{e.message}"
			end

			return "success"
		end
	end
end