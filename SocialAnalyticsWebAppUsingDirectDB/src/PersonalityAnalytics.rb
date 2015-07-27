require 'json'
require 'rest_client'
require 'tilt/erb'

def analyze_twitter_handle (param)
	handle, twitterClient, maxQueryLen = param[:handle], param[:twitterClient], param[:maxQueryLen]
	
	# defaults for dev outside bluemix
	systemu_url = 'https://gateway.watsonplatform.net/personality-insights/api'
	systemu_user = '11335c1c-3bdd-4998-90ec-b5affecae9cb'
	systemu_password = 'DadwmfoU3QUh'

	# Add a trailing slash, if it's not there
	unless systemu_url.end_with?('/')
	  systemu_url = systemu_url + '/'
	end

	profile_url = URI.join("#{systemu_url}", "v2/profile").normalize
	visualize_url = URI.join("#{systemu_url}", "v2/visualize").normalize
	@visualize_url = visualize_url
	
	auth = 'Basic ' + Base64.strict_encode64("#{systemu_user}" +':'+ "#{systemu_password}")

	@handle = handle
	@text = get_tweets(@handle, twitterClient, maxQueryLen)

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

	bad = false
	begin
		response = RestClient.post  profile_url.to_s, content.to_json, :Authorization => auth, :content_type => :json, :accept => :json, :headers => {'Content-Type:' => 'application/json'}
	rescue Exception => e
		puts "POST Request Exception"
		bad = true
	end
	if bad == false
		data = JSON.parse(response.to_str, :symbolize_names => true)
		@traits = flatten_systemu_traits(data[:tree])

		viz_response = RestClient.post visualize_url.to_s, response.to_str, :Authorization => auth, :content_type => :json, :headers => {'Content-Type:' => 'application/json'}

		@viz = viz_response.to_str
		erb :result
	else
		return "RETRIEVAL FAILURE"
	end
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

def get_tweets (handle, twitterClient, maxQueryLen)  
  jsonTweets = nil
  jsonTweets = twitterClient.searchTimeline(handle, maxQueryLen)

  puts jsonTweets

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
