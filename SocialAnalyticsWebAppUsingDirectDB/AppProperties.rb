# Setting app constants.
ROOT_APP_DIR = File.expand_path(File.dirname(__FILE__))
ROOT_SRC_DIR = "#{ROOT_APP_DIR}/src"

# Default port for the Sinatra HTTP server.
HTTP_SERVER_PORT = 80

# Files containing words for social analytics.
SENTIMENT_WORDS_DIR = "#{ROOT_APP_DIR}/sentiment-files"
GOODWORDS = File.readlines("#{SENTIMENT_WORDS_DIR}/positive_words.txt")
BADWORDS = File.readlines("#{SENTIMENT_WORDS_DIR}/negative_words.txt")
SALESWORDS = File.readlines("#{SENTIMENT_WORDS_DIR}/sales_words.txt")
MARKETINGWORDS = File.readlines("#{SENTIMENT_WORDS_DIR}/marketing_words.txt")
OPERATIONSWORDS = File.readlines("#{SENTIMENT_WORDS_DIR}/operations_words.txt")

# Cloudant properies.
CLOUDANT_DATABASE_NAME = "analytics_db"
CLOUDANT_DESIGN_DOC_NAME = "sentiment"
CLOUDANT_INDEX_NAME = "index-keyword-search"
CLOUDANT_VIEW_DIR = nil
CLOUDANT_INDEX_DIR = "#{ROOT_APP_DIR}/cloudant/indexes"

# UI properies.
MAX_TWEETS_IN_TWITTER_SEARCH = 100
TWEETS_PER_PAGE = 10

# Financial Marketplace properties.
OFFER_MATCHING_ENGINE_REST_API_URL = "http://genericruleexecengine.mybluemix.net/AnalysisGateway"

# <====== CONFIGURE THESE PROPERTIES ======>

# Twitter access credentials.
TWITTER_CONSUMER_KEY = "XA3VtiqyL9wFnzads8foWhvkn"
TWITTER_CONSUMER_SECRET = "DFli7KkyM4CLj3Ijzmpl7l4kFgNkXvbtXoE3kIbhs8ISuN8zJJ"
TWITTER_ACCESS_TOKEN = "2982251444-Rp75ynNWSya23BzAXQEWzaFoKaowOno2lqEvPUL"
TWITTER_ACCESS_TOKEN_SECRET = "4snBlPgdwFxm6pIAeP9zvf1GjqIHe4vF8sGBHBnCBwjv8"

# The email-id that will appear in the "From" section on the emails sent by SendGrid service.
# Example: "MyCompany <your.name@ibm.com>"
SENDGRID_EMAIL_FROM_ADDRESS = "Sentiment Analysis <gpingali@in.ibm.com>"

# The phone number that will appear in the "From" section on the SMS's sent by Twilio service.
# Use the same "From" phone number that you have registered in your Twilio account.
TWILIO_FROM_PHONE_NUMBER = "14155992671"

# Database settings.
DB_TYPE = "db2"
DB_HOST = "127.0.0.1"
DB_PORT = "50000"
DB_USERNAME = "db2inst1"
DB_PASSWORD = "db2inst1pwd"
DB_NAME = "TEST"