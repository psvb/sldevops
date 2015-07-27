# Loading Ruby gems.
require 'date'
require 'time'

# Analyzes the Twitter Tweets.
module TweetAnalyzer

	# Analyzes Tweets and embeds the meta-data required for generating statistics.
	def TweetAnalyzer.get_analyzed_tweets(tweets, searchKey)
		if (tweets && tweets["statuses"] && tweets["statuses"][0])
			tweetQueue = []

			# Searching each Tweet message.
			tweets["statuses"].each { |tweet|
				words = tweet["text"].split(" ")

				tally = 0
				sales = false
				marketing = false
				operations = false

				words.each { |word|
					word = word.downcase.chomp

					# Searching for Good words.
					GOODWORDS.each { |goodword|
						if (word == goodword.chomp)
							tally += 1
						end
					}

					# Searching for Bad words.
					BADWORDS.each { |badword|
						if (word == badword.chomp)
							tally -= 1
						end
					}

					# Searching for Sales related words.
					SALESWORDS.each { |salesword|
						if (word == salesword.chomp)
							sales = true
							break
						end
					}

					# Searching for Marketing related words.
					MARKETINGWORDS.each { |marketingword|
						if (word == marketingword.chomp)
							marketing = true
							break
						end
					}

					# Searching for Operations related words.
					OPERATIONSWORDS.each { |oeprationsword|
						if (word == oeprationsword.chomp)
							operations = true
							break
						end
					}
				}

				# Embedding meta-data required for generating statistics.
				tweet["searchkey"] = searchKey

				if (tally < 0)
					tweet["tally"] = "bad"
				elsif (tally == 0)
					tweet["tally"] = "indifferent"
				else
					tweet["tally"] = "good"
				end

				if sales
					tweet["sales"] = "true"
				else
					tweet["sales"] = "false"
				end

				if marketing
					tweet["marketing"] = "true"
				else
					tweet["marketing"] = "false"
				end

				if operations
					tweet["operations"] = "true"
				else
					tweet["operations"] = "false"
				end

				creationTimeStamp = tweet["created_at"]
				creationDate = date = DateTime.parse(creationTimeStamp).to_date()
				creationTimeInt = Time.parse(creationTimeStamp).to_i
        tweet["created_date"] = creationDate
        tweet["created_time_int"] = creationTimeInt
     
				tweetQueue << tweet;
			}

			return tweetQueue
		end

		return nil
	end
end