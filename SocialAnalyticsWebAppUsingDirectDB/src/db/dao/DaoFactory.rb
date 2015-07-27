# Loading app libraries.
require "#{ROOT_SRC_DIR}/db/connector/DbConnectorFactory"
require "#{ROOT_SRC_DIR}/db/dao/CustomerDao"

# Factory which returns various Data Access Objects.
class DaoFactory
	def initialize(dbType, dbHost, dbPort, dbUserName, dbPassword, dbName)
		@dbType = dbType
		@dbHost = dbHost
		@dbPort = dbPort
		@dbUserName = dbUserName
		@dbPassword = dbPassword
		@dbName = dbName
	end

	def get_customer_dao()
		dbConnector = get_db_connector()

		if dbConnector
			return CustomerDao.new(dbConnector)
		end

		# Return nil if there is no matching DbConnector for the given dbType.
		return nil
	end

	# Functions that follow the 'private' keyword will be private and won't be accessible from outside.
	private

	def get_db_connector()
		return DbConnectorFactory.get_db_connector(@dbType, @dbHost, @dbPort, @dbUserName, @dbPassword, @dbName)
	end
end