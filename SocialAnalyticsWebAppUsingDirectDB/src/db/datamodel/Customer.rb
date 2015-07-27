# Datamodel to encapsulate a single row/record of the CUSTOMER database table.
class Customer
	def set_twitter_id(twitterId)
		@twitterId = twitterId
	end

	def get_twitter_id()
		return @twitterId
	end

	def set_name(name)
		@name = name
	end

	def get_name()
		return @name
	end

	def set_phone(phone)
		@phone = phone
	end

	def get_phone()
		return @phone
	end

	def set_email(email)
		@email = email
	end

	def get_email()
		return @email
	end
end