# Loading app libraries.
require "#{ROOT_SRC_DIR}/db/datamodel/Customer"

# Data Access Object class for Customer database table.
class CustomerDao
	def initialize(dbConnector)
		@dbConnector = dbConnector
	end

	# Get the details of a Customer who has the given Twitter_Id.
	def get_customer(twitterId)
		sql = "select * from CUSTOMER where TWITTER_ID='#{twitterId}'"
		result = @dbConnector.execute_sql(sql)

		if (result)
			# If there is any error throw it back to the caller.
			error = result.get_error()

			if error
				raise error
			end

			# If there is no error, proceed to process to resultant rows.
			resultRows = result.get_result_rows()

			if (resultRows && !resultRows.empty?())
				# Create a new Customer datamodel instance and populate it with the details of the first Customer only.
				customer = Customer.new()
				firstCustomer = resultRows[0]
				customer.set_twitter_id(firstCustomer["TWITTER_ID"])
				customer.set_name(firstCustomer["NAME"])
				customer.set_phone(firstCustomer["PHONE"])
				customer.set_email(firstCustomer["EMAIL"])

				# Return the Customer datamodel instance back to the caller.
				return customer
			end
		end

		# Return nil if there is no matching Customer for the given Twitter_Id.
		return nil
	end

	def add_customer(customerDataModelObject)
		if customerDataModelObject
			twitterId = customerDataModelObject.get_twitter_id()
			name = customerDataModelObject.get_name()
			phone = customerDataModelObject.get_phone()
			email = customerDataModelObject.get_email()

			sql = "insert into CUSTOMER (TWITTER_ID, NAME, PHONE, EMAIL) VALUES ('#{twitterId}', '#{name}', '#{phone}','#{email}')"
			result = @dbConnector.execute_sql(sql)

			if (result)
				# If there is any error throw it back to the caller.
				error = result.get_error()

				if error
					raise error
				end
			end
		end
	end
end