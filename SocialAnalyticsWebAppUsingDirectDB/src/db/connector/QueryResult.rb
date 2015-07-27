# A class whose object is intended to encapsulate a SQL execution result.
class QueryResult
	def set_result_rows(rows)
		@rows = rows
	end

	def get_result_rows()
		return @rows
	end

	def set_error(error)
		@error = error
	end

	def get_error()
		return @error
	end
end