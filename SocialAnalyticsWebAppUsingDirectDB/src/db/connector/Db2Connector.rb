# Loading Ruby gems.
require 'ibm_db'

# Loading app libraries.
require "#{ROOT_SRC_DIR}/db/connector/QueryResult"

# Connector for DB2 database.
class Db2Connector
	# Constructor function.
	def initialize(dbHost, dbPort, dbUserName, dbPassword, dbName)
		@dbHost = dbHost
		@dbPort = dbPort
		@dbUserName = dbUserName
		@dbPassword = dbPassword
		@dbName = dbName
	end

	def execute_sql(sql)
		result = QueryResult.new()
		conn = get_db_connection()

		if conn
			begin
				# Executing the SQL.
				stmt = IBM_DB.exec(conn, sql)

				if stmt
					# Retrieve resultant rows if any.
					rows = Array.new()

					begin
						while (row = IBM_DB.fetch_assoc(stmt))
							rows << row
						end
					rescue Exception => e
						# Looks like a non query SQL statement has been executed.
						# So, set resultant rows to nil.
						rows = nil
					end

					# Setting resultant rows in Query Result.
					result.set_result_rows(rows)

					IBM_DB.free_result(stmt)
				else
					result.set_error("#{IBM_DB.getErrormsg()}")
				end
			ensure
				# Close database connection.
				IBM_DB.close(conn)
			end
		else
			result.set_error("#{IBM_DB.getErrormsg()}")
		end

		# Return Query Result to the caller.
		return result
	end

	# Functions that follow the 'private' keyword will be private and won't be accessible from outside.
	private

	def get_db_connection()
		return IBM_DB.connect("DRIVER={IBM DB2 ODBC DRIVER};DATABASE=#{@dbName};HOSTNAME=#{@dbHost};PORT=#{@dbPort};PROTOCOL=TCPIP;UID=#{@dbUserName};PWD=#{@dbPassword};", "", "")
	end
end