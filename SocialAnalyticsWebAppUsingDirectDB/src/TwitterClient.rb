# Loading Ruby gems.
require "oauth"
require 'json'
require 'uri'

# A client to interact with Twitter.
module Twitter
	class Client
		# Declaring global constants.
		TWEETS_SEARCH_URL = 'https://api.twitter.com/1.1/search/tweets.json'
		TWEETS_TIMELINE_URL = 'https://api.twitter.com/1.1/statuses/user_timeline.json'

		# Constructor function.
		def initialize(consumerKey, consumerSecret, accessToken, accessTokenSecret)
			# Setting Twitter access properties.
			@consumerKey = consumerKey
			@consumerSecret = consumerSecret
			@accessToken = accessToken
			@accessTokenSecret = accessTokenSecret

			# Getting OAuth access token for accessing Twitter.
			# Creating the OAuth consumer.
			consumer = OAuth::Consumer.new(@consumerKey, @consumerSecret, {
				:site => "http://api.twitter.com",
				:scheme => :header
			})

			# Exchanging our access token for the OAuth access token.
			tokenHash = {
				:oauth_token => @accessToken,
				:oauth_token_secret => @accessTokenSecret
			}

			@oauthAccessToken = OAuth::AccessToken.from_hash(consumer, tokenHash)
		end

		# Searches for Tweets.
		def searchTweets(searchKey, maxResultCount, showUser, sinceId = nil)
			# Encoding the search key before attaching it to the URL.
			searchKey = URI.encode_www_form_component(searchKey)

			# Setting URL parameters.
			urlParams = "?q=#{searchKey}&count=#{maxResultCount}&show_user=#{showUser}&lang=en"

			if sinceId
				urlParams = urlParams + "&since_id=#{sinceId}"
			end

			url = TWEETS_SEARCH_URL + urlParams

			response = @oauthAccessToken.request(:get, url)

			if response
				return JSON.parse(response.body)
			end

			return nil
		end
		
		def searchTimeline(searchKey, maxResultCount)
			urlParams = "?screen_name=#{searchKey}&count=#{maxResultCount}"
			url =  TWEETS_TIMELINE_URL + urlParams
			response = @oauthAccessToken.request(:get, url)

			if response
				return JSON.parse(response.body)
			end
			return nil
		end

	end
end