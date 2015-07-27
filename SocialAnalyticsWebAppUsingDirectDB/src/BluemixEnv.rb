# Loading Ruby gems.
require 'json'

# Provides information about the current Bluemix environment.
module BluemixEnv
	# JSON object containing information about the entire Bluemix services.
	$globalServicesEnvJson = nil

	# Returns the content of the given file as string.
	# Returns nil if file does not exist or is not a file at all.
	def BluemixEnv.getFileContent(file)
		if (File.exists?(file) and File.file?(file))
			fileHandle = File.open(file)
			fileContent = fileHandle.read
			fileHandle.close
			return fileContent
		end

		return nil
	end

	# Gets information about the entire Bluemix services as a JSON object.
	def BluemixEnv.get_service_env()
		# Set the global Service environment variables if not set already.
		if ($globalServicesEnvJson == nil)
			if ENV
				# Commented since ONLY hardcoded values will be used for this demo.
				# Uncomment this line if you want to use the local Bluemix environment.
				globalServicesEnv = nil #globalServicesEnv = ENV['VCAP_SERVICES']

				# If Bluemix 'VCAP_SERVICES' env mapping is not available, use a local file instead.
				if (globalServicesEnv == nil)
					globalServicesEnv = BluemixEnv.getFileContent("#{ROOT_APP_DIR}/auth.json")
				end

				if globalServicesEnv
					$globalServicesEnvJson = JSON.parse(globalServicesEnv)
				end
			end
		end

		return $globalServicesEnvJson
	end

	# Provides environment details of a specific Bluemix service.
	module Service
		# Gets the environment details of the given Bluemix service.
		def Service.get_env(serviceCategoryName)
			if (serviceCategoryName == nil)
				raise "Service category name not set!"
			end

			servicesEnv = BluemixEnv.get_service_env()

			if servicesEnv
				serviceEnv = servicesEnv[serviceCategoryName]

				if serviceEnv
					# Getting the first listed service and ignoring others.
					return serviceEnv[0]
				end
			end

			return nil
		end

		# Gets the credentials of the given Bluemix service.
		def Service.get_credentials(serviceCategoryName)
			serviceEnv = Service.get_env(serviceCategoryName)

			if serviceEnv
				return serviceEnv['credentials']
			end

			return nil
		end

		module SendGrid
			SENDGRID_SERVICE_CATEGORY_NAME = "sendgrid"

			def SendGrid.get_credentials()
				return Service.get_credentials(SENDGRID_SERVICE_CATEGORY_NAME)
			end
		end

		module Twilio
			TWILIO_SERVICE_CATEGORY_NAME = "user-provided"

			def Twilio.get_credentials()
				return Service.get_credentials(TWILIO_SERVICE_CATEGORY_NAME)
			end
		end

		module Cloudant
			CLOUDANT_SERVICE_CATEGORY_NAME = "cloudantNoSQLDB"

			def Cloudant.get_credentials()
				return Service.get_credentials(CLOUDANT_SERVICE_CATEGORY_NAME)
			end
		end

		# Provides details of the current Bluemix Cloud Integration service.
		module CloudIntegration
			CLOUD_INTEGRATION_SERVICE_CATEGORY_NAME = "CloudIntegration"

			# Gets the credentials of the current Cloud Integration service.
			def CloudIntegration.get_credentials()
				return Service.get_credentials(CLOUD_INTEGRATION_SERVICE_CATEGORY_NAME)
			end

			# Gets the environment details of all the Cloud Integration API's 
			# created for the current Cloud Integration service.
			def CloudIntegration.get_all_apis()
				serviceCred = Service.get_credentials(CLOUD_INTEGRATION_SERVICE_CATEGORY_NAME)

				if serviceCred
					return serviceCred['apis']
				end

				return nil
			end

			# Gets the environment details of the current Cloud Integration API.
			def CloudIntegration.get_api(apiName)
				apis = CloudIntegration.get_all_apis()

				if apis
					apis.each { |api|
						if (api["name"] == apiName)
							return api
						end
					}
				end

				return nil
			end
		end
	end
end