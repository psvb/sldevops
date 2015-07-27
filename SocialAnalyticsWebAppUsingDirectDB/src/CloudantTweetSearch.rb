def replace_forbidden_cloudant_characters(str)
	return str.gsub("\"", "")
end

def get_latest_tweet_id(searchKey)
	searchKey = replace_forbidden_cloudant_characters(searchKey)

	tweetMsgQuery = {
		:fields => ["id_str"],
		:selector => {
			:searchkey => "#{searchKey}"
		},
		:limit => 1
	}

	response = $cloudantClient.search_query_index(tweetMsgQuery)
	payload = response.get_payload()

	if payload
		payloadJson = JSON.parse(payload)
		docs = payloadJson["docs"];

		if (docs && docs[0])
			# Return the Tweet id.
			return docs[0]["id_str"]
		end
	end

	return nil
end

def get_tweet_chart_data(searchKey)
	searchKey = replace_forbidden_cloudant_characters(searchKey)

	chartQuery = {
		:query => "searchkey:\"#{searchKey}\"",
		:counts => ["tally","sales","marketing","operations"]
	}

	response = $cloudantClient.search_primary_index(CLOUDANT_DESIGN_DOC_NAME, CLOUDANT_INDEX_NAME, chartQuery)
	payload = response.get_payload()

	if payload
		payloadJson = JSON.parse(payload)
		totalRows = payloadJson["total_rows"]

		if (totalRows && (totalRows > 0))
			counts = payloadJson["counts"]
			tally = counts["tally"]
			marketing = counts["marketing"]
			marketingCount = marketing["true"]
			operations = counts["operations"]
			operationsCount = operations["true"]
			sales = counts["sales"]
			salesCount = sales["true"]

			return {
				:sentimentChartData => tally, 
				:omsChartData => {
					:marketing => marketingCount, 
					:operations => operationsCount, 
					:sales => salesCount
				}
			}
		end
	end

	return nil
end

def get_tweet_trend_data(searchKey)
	searchKey = replace_forbidden_cloudant_characters(searchKey)

	tweetTrendQuery = {
		:fields => ["created_date", "tally"],
		:selector => {
			:searchkey => "#{searchKey}"
		}
	}

	response = $cloudantClient.search_query_index(tweetTrendQuery)
	payload = response.get_payload()

	if payload
		payloadJson = JSON.parse(payload)
		docs = payloadJson["docs"]

		if docs
			dataMap = {}

			docs.each { |tweetData|
				tally = tweetData["tally"]
				created_date = tweetData["created_date"]
				tallyMap = dataMap[tally]

				if tallyMap
					tweetCount = tallyMap["#{created_date}"]

					if tweetCount
						tallyMap["#{created_date}"] = (tweetCount+1)
					else
						tallyMap["#{created_date}"] = 1
					end
				else
					dataMap[tally] = {"#{created_date}" => 1}
				end
			}

			if (dataMap.empty? == false)
				return dataMap
			end
		end
	end

	return nil
end

def get_tweet_messages(searchKey, pageNumber)
	searchKey = replace_forbidden_cloudant_characters(searchKey)
	
	# Converting string page-number to integer.
	if pageNumber
		pageNumber = pageNumber.to_i()
	else
		# Default value if page number not set.
		pageNumber = 1
	end

	# Calculating tweets to be askipped.
	skippedTweets = ((pageNumber - 1) * TWEETS_PER_PAGE)

	tweetMsgQuery = {
		:fields => ["created_date", "user.screen_name", "user.name", "user.location", "user.followers_count", "user.friends_count", "retweet_count", "tally", "text","created_time_int"],
		:selector => {
			:searchkey => "#{searchKey}",
      :created_time_int => {"$gte" => 10}
		},
    :sort => [{"created_time_int" => "desc"}],
		:limit => TWEETS_PER_PAGE,
		:skip => skippedTweets,
	}

	response = $cloudantClient.search_query_index(tweetMsgQuery)
  puts "Tis is response"
  puts JSON.parse(response.get_payload())
	return "#{response.get_payload()}"
end

def get_sentiment_alchemy(tweet,search)
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
    #get_string = "http://localhost:3000/analyze-url?url=" + uri.to_s + "&search=" + search.to_s

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
  return type
end

