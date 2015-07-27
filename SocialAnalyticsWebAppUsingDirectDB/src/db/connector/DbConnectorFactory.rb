# Loading app libraries.
require "#{ROOT_SRC_DIR}/db/connector/Db2Connector"

# Creates an instance of a database connector.
module DbConnectorFactory
	def DbConnectorFactory.get_db_connector(dbType, dbHost, dbPort, dbUserName, dbPassword, dbName)
		if (dbType == "db2")
			return Db2Connector.new(dbHost, dbPort, dbUserName, dbPassword, dbName)
		end

		return nil
	end
end