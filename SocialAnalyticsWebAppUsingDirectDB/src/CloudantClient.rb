# Loading Ruby gems.
require 'json'
require 'uri'

# Loading app libraries.
require "#{ROOT_SRC_DIR}/HttpClient"

# A client to interact with a Cloudant database.
module Cloudant
	class Client
		# Constructor function.
		def initialize(host, userName, password, databaseName)
			@host = host
			@userName = userName
			@password = password
			@databaseName = databaseName
			@cloudantRootUrl = "https://#{@userName}:#{@password}@#{@host}/#{@databaseName}"
			@cloudantDesignDocUrl = "#{@cloudantRootUrl}/_design"
			@cloudantIndexCreateUrl = "#{@cloudantRootUrl}/_index"
			@cloudantIndexSearchUrl = "#{@cloudantRootUrl}/_find"
			@cloudantPersistUrl = "#{@cloudantRootUrl}/_bulk_docs"
		end

		def create_database()
			httpHeaders = {:accept => :json}
			return HttpClient.put(@cloudantRootUrl, nil, httpHeaders)
		end

		# Creates query index for the given array of Cloudant document fields.
		def create_query_index(fieldArray)
			payload = {:index => {:fields => fieldArray}}.to_json()
			httpHeaders = {:content_type => :json, :accept => :json}
			return HttpClient.post(@cloudantIndexCreateUrl, payload, httpHeaders)
		end

		def search_query_index(query)
			payload = query.to_json()
			httpHeaders = {:content_type => :json, :accept => :json}
			return HttpClient.post(@cloudantIndexSearchUrl, payload, httpHeaders)
		end

		def create_design_document(designDocName, viewsDir = nil, indexesDir = nil)
			# Constructing the design document.
			doc = {}
			doc[:_id] = "_design/#{designDocName}"
			doc[:language] = "javascript"

			if viewsDir
				# List all Cloudant view script directories in the ROOT Cloudant view directory.
				viewDirs = Dir.glob("#{viewsDir}/*")

				# Check if atleast one Cloudant view script directory exists.
				if viewDirs[0]
					views = {}

					# Iterate through the Cloudant view script directories.
					viewDirs.each { |viewDir|
						# Use the name of the Cloudant view script directory as the Cloudant view name.
						viewName = File.basename(viewDir)

						# Reading Cloudant view scripts.
						scripts = {}

						# Reading Cloudant Map script.
						viewMap = Dir.glob("#{viewDir}/map*")[0]

						if viewMap
							mapFile = File.open(viewMap, "rb")
							mapScript = mapFile.read()
							scripts[:map] = mapScript
						end

						# Reading Cloudant Reduce script.
						viewReduce = Dir.glob("#{viewDir}/reduce*")[0]

						if viewReduce
							reduceFile = File.open(viewReduce, "rb")
							reduceScript = reduceFile.read()
							scripts[:reduce] = reduceScript
						end

						# Check if Cloudant view scripts are available.
						if (scripts.empty? == false)
							# Create Cloudant database view.
							views["#{viewName}"] = scripts
						end
					}

					# Check if Cloudant views are available.
					if (views.empty? == false)
  						# Attaching the Cloudant database views to the Cloudant database design document.
						doc[:views] = views
					end
				end
			end

			if indexesDir
				# List all Cloudant index script directories in the ROOT Cloudant index directory.
				indexDirs = Dir.glob("#{indexesDir}/*")

				# Check if atleast one Cloudant index script directory exists.
				if indexDirs[0]
					indexes = {}

					# Iterate through the Cloudant index script directories.
					indexDirs.each { |indexDir|
						# Use the name of the Cloudant index script directory as the Cloudant index name.
						indexName = File.basename(indexDir)

						# Reading Cloudant index scripts.
						index = Dir.glob("#{indexDir}/*")[0]

						if index
							indexFile = File.open(index, "rb")
							indexScript = indexFile.read()
							indexes["#{indexName}"] = JSON.parse(indexScript)
						end
					}

					# Check if Cloudant indexes are available.
					if (indexes.empty? == false)
  						# Attaching the Cloudant database indexes to the Cloudant database design document.
						doc[:indexes] = indexes
					end
				end
			end

			# Creating the Cloudant database design document.
			url = "#{@cloudantDesignDocUrl}/#{designDocName}"
			payload = doc.to_json()
			httpHeaders = {:content_type => :json, :accept => :json}

			return HttpClient.put(url, payload, httpHeaders)
		end

		def search_primary_index(designDocName, indexName, queryParamMap)
			# Constructing URL params.
			params = nil

			queryParamMap.each_key { |key|
  				# Encoding the value before attaching it to the URL.
				value = queryParamMap[key]
				value = URI.encode_www_form_component(value)

				if params
					params += "&#{key}=#{value}"
				else
					params = "#{key}=#{value}"
				end
  			}

			url = "#{@cloudantDesignDocUrl}/#{designDocName}/_search/#{indexName}?#{params}"
			httpHeaders = {:accept => :json}

			return HttpClient.get(url, httpHeaders)
		end

		# Saves the given documents in the Cloudant database.
		def persist_docs(docs)
			payload = {:docs => docs}.to_json()
			httpHeaders = {:content_type => :json, :accept => :json}

			return HttpClient.post(@cloudantPersistUrl, payload, httpHeaders)
		end
	end
end