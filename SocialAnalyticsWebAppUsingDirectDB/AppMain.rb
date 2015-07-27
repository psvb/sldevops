# Loading Ruby gems.
require 'sinatra'
require 'json'
require 'open-uri'

# Loading app libraries.
require './AppProperties'
require "#{ROOT_SRC_DIR}/BluemixEnv"
require "#{ROOT_SRC_DIR}/CloudantClient"
require "#{ROOT_SRC_DIR}/TwitterClient"
require "#{ROOT_SRC_DIR}/TweetAnalyzer"
require "#{ROOT_SRC_DIR}/CloudantTweetSearch"
require "#{ROOT_SRC_DIR}/TwilioClient"
require "#{ROOT_SRC_DIR}/SendGridClient"
require "#{ROOT_SRC_DIR}/HttpClient"
require "#{ROOT_SRC_DIR}/db/dao/DaoFactory"
require "#{ROOT_SRC_DIR}/db/datamodel/Customer"

# Overriding the default port setting for the Sinatra HTTP server.
set :port, HTTP_SERVER_PORT

# Declaring global variables.
$envSetupErrors = Array.new()
$cloudantClient = nil
$twitterClient = nil
$sendgridClient = nil
$twilioClient = nil
$customerDao = nil

# Check if the required Twitter access credentials are set.
if ((TWITTER_CONSUMER_KEY == nil) || (TWITTER_CONSUMER_SECRET == nil) || (TWITTER_ACCESS_TOKEN == nil) || (TWITTER_ACCESS_TOKEN_SECRET == nil))
	$envSetupErrors << "Set Twitter access credentials in AppProperties.rb file and redeploy the application."
end

# Check availability of the required Bluemix services.
# Check if Cloudant Bluemix service is configured for the application.
CLOUDANT_SERVICE_ENV = BluemixEnv::Service::Cloudant.get_credentials()

if (CLOUDANT_SERVICE_ENV == nil)
	$envSetupErrors << "Configure a Cloudant Bluemix service for the application."
end

# Check if SendGrid Bluemix service is configured for the application.
SENDGRID_SERVICE_ENV = BluemixEnv::Service::SendGrid.get_credentials()

if (SENDGRID_SERVICE_ENV == nil)
	$envSetupErrors << "Configure a SendGrid Bluemix service for the application."
end

# Check if Twilio Bluemix service is configured for the application.
TWILIO_SERVICE_ENV = BluemixEnv::Service::Twilio.get_credentials()

if (TWILIO_SERVICE_ENV == nil)
	$envSetupErrors << "Configure a Twilio Bluemix service for the application."
end

# Creating Customer Data Access Object.
daoFactory = DaoFactory.new(DB_TYPE, DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_NAME)

if daoFactory
	$customerDao = daoFactory.get_customer_dao()
else
	$envSetupErrors << "Unsupported database type: '#{DB_TYPE}'."
end

# If all the required Bluemix services are configured for the application, proceed further.
if $envSetupErrors.empty?()
	# Getting Cloudant environment details.
	cloudantHost = CLOUDANT_SERVICE_ENV["host"]
	cloudantUserName = CLOUDANT_SERVICE_ENV["username"]
	cloudantPassword = CLOUDANT_SERVICE_ENV["password"]

	# Getting SendGrid environment details.
	sendgridHostName = SENDGRID_SERVICE_ENV["hostname"]
	sendgridUserName = SENDGRID_SERVICE_ENV["username"]
	sendgridPassword = SENDGRID_SERVICE_ENV["password"]

	# Getting Twilio environment details.
	twilioAccountSid = TWILIO_SERVICE_ENV["accountSID"]
	twilioAuthToken = TWILIO_SERVICE_ENV["authToken"]

	# Creating clients.
	$cloudantClient = Cloudant::Client.new(cloudantHost, cloudantUserName, cloudantPassword, CLOUDANT_DATABASE_NAME)
	$twitterClient = Twitter::Client.new(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET)
	$sendgridClient = SendGrid::Client.new(sendgridHostName, sendgridUserName, sendgridPassword)
	$twilioClient = Twilio::Client.new(twilioAccountSid, twilioAuthToken)

	# Setup cloudant database.
	puts "Creating cloudant database..."
	$cloudantClient.create_database()
	puts "Creating cloudant design document..."
	$cloudantClient.create_design_document(CLOUDANT_DESIGN_DOC_NAME, CLOUDANT_VIEW_DIR, CLOUDANT_INDEX_DIR)
	puts "Creating cloudant query index..."
	$cloudantClient.create_query_index(["searchkey"])
	$cloudantClient.create_query_index(["created_time_int"])
	puts "Completed cloudant setup."
end

enable :sessions

get '/' do
	# If one or more environment setup errors exist, show error page.
	if (!$envSetupErrors.empty?())
		errorPageHtml = "<html><body><h2>Application Setup Error</h2><b><u>Please, fix the following errors and restart or redeploy the application:</u></b><br><ul>"

		$envSetupErrors.each { |error|
			errorPageHtml = "#{errorPageHtml}<li>#{error}</li>"
		}

		errorPageHtml = "#{errorPageHtml}</ul></body></html>"
		return errorPageHtml
	end

	return File.read(File.join('public', 'index.html'))
end

get '/search-tweets' do
	# Getting the search-key from HTTP request.
	searchKey = params[:searchKey]

	# Storing the search-key in the HTTP session for future usage during pagination.
	session[:searchKey] = searchKey

	# Getting the latest Tweet message id for the given search-key from the Cloudant database.
	latestTweetId = get_latest_tweet_id(searchKey)

	jsonTweets = nil

	if latestTweetId
		# Getting Tweet updates from Twitter that came after the latest Tweet message id.
		jsonTweets = $twitterClient.searchTweets(searchKey, MAX_TWEETS_IN_TWITTER_SEARCH, false, latestTweetId)
	else
		# If the Cloudant database doesn't contain any docs for the given search-key, search Twitter for Tweets.
		jsonTweets = $twitterClient.searchTweets(searchKey, MAX_TWEETS_IN_TWITTER_SEARCH, false)
	end

	# If Tweets are available, analyze the Tweets and append meta-data.
	if jsonTweets
		analyzedJsonTweets = TweetAnalyzer.get_analyzed_tweets(jsonTweets, searchKey)

		# Store the analyzed Twieets in the Cloudant database.
		if analyzedJsonTweets
			$cloudantClient.persist_docs(analyzedJsonTweets)
		end
	end

	# Getting Tweet chart data.
	tweetChartData = get_tweet_chart_data(searchKey)

	if tweetChartData
		searchResult = {}

		# Getting Tweet trend data.
		tweetTrendData = get_tweet_trend_data(searchKey)

		# Getting Tweet messages.
		tweetsStr = get_tweet_messages(searchKey, 1)
		tweetsJson = JSON.parse(tweetsStr)

		# Constructing the search result.
		tweetChartData.each_key { |key|
			searchResult[key] = tweetChartData[key]
		}

		searchResult[:sentimentTrendData] = tweetTrendData
		searchResult[:docs] = tweetsJson["docs"]

		return searchResult.to_json()
	end

	# Return empty string if there are no Tweets.
	return ""
end

get '/get-tweets' do
	# Getting search-key from HTTP session.
	searchKey = session[:searchKey]

	# Getting the next page-number from HTTP request.
	pageNumber = params[:page]

	return get_tweet_messages(searchKey, pageNumber)
end

post '/send-email' do
	if (params.empty? == false)
		data = params[:data]

		if data
			jsonData = JSON.parse(data)
			emailIdList = jsonData["emailIdList"]
			emailMsg = jsonData["emailMsg"]
			subjectLine = "Tweet message."

			clientResponse = $sendgridClient.sendEmail(SENDGRID_EMAIL_FROM_ADDRESS, emailIdList, subjectLine, emailMsg)

			if (clientResponse == "success")
				return "Email sent successfully."
			else
				return clientResponse
			end
		end
	end
end

post '/send-sms' do
	if (params.empty? == false)
		data = params[:data]

		if data
			jsonData = JSON.parse(data)
			phoneNumber = jsonData["phoneNumber"]
			smsMsg = jsonData["smsMsg"]

			clientResponse = $twilioClient.sendSMS(TWILIO_FROM_PHONE_NUMBER, phoneNumber, smsMsg)

			if (clientResponse == "success")
				return "SMS sent successfully to phone number '#{phoneNumber}'."
			else
				return clientResponse
			end
		end
	end
end

get '/get-customer-info' do
	twitterId = params[:twitterId]

	if twitterId
		# Search the Customer database with Twitter id.
		customer = $customerDao.get_customer(twitterId)

		if customer
			# If a matching Customer is found, return the details.
			name = customer.get_name()
			phone = customer.get_phone()
			email = customer.get_email()
			return "{\"rows\":{\"row\":{\"NAME\":\"#{name}\",\"PHONE\":\"#{phone}\",\"EMAIL\":\"#{email}\",\"TWITTER_ID\":\"#{twitterId}\"}}}"
		else
			# If a matching Customer is NOT found, return default response.
			return "{\"rows\":null}"
		end
	end

	return ""
end

post '/get-matching-offers' do
	# Setting content-type HTTP response header using Sinatra's inbuilt "response" object.
	response['Content-Type'] = "application/json"

	if (params.empty? == false)
		data = params[:data]

		if data
			httpHeaders = {:accept => :json}
			httpResponse = HttpClient.post(OFFER_MATCHING_ENGINE_REST_API_URL, data, httpHeaders)

			if httpResponse
				httpResponsePayload = httpResponse.get_payload()

				if httpResponsePayload
					return httpResponsePayload
				else
					httpStatusCode = httpResponse.get_http_status_code()
					puts "Error: Offer Matching Engine did not return any response. HTTP Status Code: #{httpStatusCode}."
				end
			end
		end
	end

	# Default response for 0 matching offers.
	return "{\"offers\":[]}"
end

# Admin functionality.
# Shows admin page.
get '/admin' do
	return File.read(File.join('public', 'admin.html'))
end

post '/add-customer' do
	if (params.empty? == false)
		data = params[:data]

		if data
			# Getting the customer details.
			jsonData = JSON.parse(data)
			twitterId = jsonData["twitterId"]
			customerName = jsonData["customerName"]
			phoneNumber = jsonData["phoneNumber"]
			emailId = jsonData["emailId"]

			# Populating the Customer datamodel.
			customerDataModelObject = Customer.new()
			customerDataModelObject.set_twitter_id(twitterId)
			customerDataModelObject.set_name(customerName)
			customerDataModelObject.set_phone(phoneNumber)
			customerDataModelObject.set_email(emailId)

			begin
				# Inserting the Customer details into the Customer database.
				$customerDao.add_customer(customerDataModelObject)
			rescue Exception => e
				# Logging the exception.
				puts "Exception while adding Customer: #{e}"

				# Return a failed status response.
				return "failed"
			end
		end
	end

	# Default status response.
	return "success"
end

# Sam's code.
post '/get-alchemy-sentiment' do
  sentiment = 0
  tweet  = params[:tweet]
  #URI encode the search string to properly pass that onto the API
  search = URI.escape(params[:search])
  
  #create an array of urls from the tweet
  url_arr = Array.new
  begin
    url_arr = URI.extract(tweet,"http")
  rescue Exception => e
    puts "Exception: " + e
  end
  
  #loop through the url array and create a sum of sentiment scores
  total_sentiment_score = 0
  record_count = 0
  url_arr.each do |url|
    uri = URI.escape(url)
    httpHeaders = {:accept => :json}
    get_string = "http://testalchemy-sam.mybluemix.net/analyze-url?url=" + uri.to_s + "&search=" + search.to_s
	
    httpResponse = HttpClient.get(get_string, httpHeaders)
    
    json = JSON.parse(httpResponse.get_payload)
  
    if defined? json["docSentiment"]["score"]
      total_sentiment_score +=  json["docSentiment"]["score"].to_f
      record_count += 1
    end
  end
  
  if record_count > 0
    sentiment = total_sentiment_score.to_f/record_count.to_i
  else
	get_string = "http://testalchemy-sam.mybluemix.net/analyze-text?text=" + URI::encode(tweet) + "&search=" + URI::encode(search)
    httpHeaders = {:accept => :json}
    httpResponse = HttpClient.get(get_string, httpHeaders)
	json = JSON.parse(httpResponse.get_payload)
	if defined? json["docSentiment"]["score"]
      sentiment =  json["docSentiment"]["score"].to_f
	else
	  type = "neutral"
	  sentiment = 0
    end
  end
  if type != "neutral"
	  if sentiment < 0
		type = "negative"
	  else sentiment > 0
		type = "positive"
	  end
  end
 
  json = { :score => sentiment.to_s, :type => type.to_s }.to_json
  return json
end

get '/personality-insight' do
  handle = params[:handle]
  analyze_twitter_handle (handle)
end

post '/get-sentiment-analysis' do
	search = nil

	if (params.empty? == false)
		data = params[:data]

		if data
			jsonData = JSON.parse(data)
			search = jsonData["searchKey"]
			url_arr = jsonData["websitesToAnalyze"]
		else
			puts "Request payload doesn't contain any data!"
		end
	else
		puts "Request payload is empty!"
	end

	#URI encode the search string to properly pass that onto the API
	if defined?(params[:search]) && params[:search] != nil
		search = URI.escape(params[:search])
	else
		puts "Parameter is not define"
	end

	innerJson = Array.new
	url_arr.each do |url|
		uri = URI.escape(url)
		httpHeaders = {:accept => :json}
		get_string = "http://testalchemy-sam.mybluemix.net/analyze-url-with-target?url=" + uri.to_s + "&search=" + search.to_s.gsub(' ', '+')

		httpResponse = HttpClient.get(get_string, httpHeaders)
		json = JSON.parse(httpResponse.get_payload)
		
		count = 0
		if json["status"] == "ERROR"
			count += 1
			temp = {:uri => uri.to_s, :target => search.to_s, :score => "0", :type => "neutral"}
		else
			temp = {:uri => uri.to_s, :target => search.to_s, :score => json["docSentiment"]["score"], :type => json ["docSentiment"]["type"]}
		end

		innerJson.push(temp)
	end

	json = {"data" => innerJson}.to_json
	return json
end

############################
# PERSONALITY INSIGHTS Code
############################
def analyze_twitter_handle (handle)
	log = Logger.new(STDOUT)
	log.level = Logger::DEBUG

	# Add a trailing slash, if it's not there
	systemu_url = 'https://gateway.watsonplatform.net/personality-insights/api'
	systemu_user = '11335c1c-3bdd-4998-90ec-b5affecae9cb'
	systemu_password = 'DadwmfoU3QUh'
	
	unless systemu_url.end_with?('/')
	  systemu_url = systemu_url + '/'
	end

	profile_url = URI.join("#{systemu_url}", "v2/profile").normalize
	visualize_url = URI.join("#{systemu_url}", "v2/visualize").normalize

	@visualize_url = visualize_url

	auth = 'Basic ' + Base64.strict_encode64("#{systemu_user}" +':'+ "#{systemu_password}")

	@handle = handle
	@text = get_tweets(@handle)

	content = {
	:contentItems => [{
	:userid => 'samuzzal',
	:id => '333a22b9-e12b-4220-8ae2-ca678bb9cf6c',
	:sourceid => 'freetext',
	:contenttype => 'text/plain',
	:language => 'en',
	:created => 1393264847000,
	:content => @text
	}]
	}

	response = RestClient.post  profile_url.to_s, content.to_json, :Authorization => auth, :content_type => :json, :accept => :json, :headers => {'Content-Type:' => 'application/json'}

	data = JSON.parse(response.to_str, :symbolize_names => true)
	@traits = flatten_systemu_traits(data[:tree])

	viz_response = RestClient.post visualize_url.to_s, response.to_str, :Authorization => auth, :content_type => :json, :headers => {'Content-Type:' => 'application/json'}

	@viz = viz_response.to_str
	erb :result
end

def flatten_systemu_traits(traits)
  arr = flatten_level(traits, 0)
  return arr
end

def flatten_level(t, level)
  arr = []
  if (level > 0 && ((not t.has_key?(:children)) || level != 2))
    obj = {
      :id => t[:id]
    }
    obj[:title] = t.has_key?(:children)
    if t.has_key?(:percentage)
      obj[:value] = (t[:percentage] * 100).floor.to_s + "%"
    end
    arr.push(obj)
  end
  if t.has_key?(:children) && t[:id] != "sbh"
    t[:children].each do |child|
      arr.push(flatten_level(child, level + 1))
    end
  end
  return arr.flatten
end

def get_tweets (handle)
  jsonTweets = nil
  jsonTweets = $twitterClient.searchTimeline(handle, MAX_TWEETS_IN_TWITTER_SEARCH)
  return get_analyzed_text(jsonTweets)
end

def get_analyzed_text (tweets)
  words = ""
  if (tweets)
    tweets.each { |tweet|
      words = words + tweet["text"] + "\n"
    }
  end
  return words
end