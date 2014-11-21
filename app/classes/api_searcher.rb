class ApiSearcher
  # require 'twitter'
  # require 'sentimental'
  # require 'indico'
  # require 'descriptive-statistics'
  # attr_accessor :tweets_collection, :tweets_status, :results_hash, :tagging_hash, :largest_tag, :return_top_three_tags_keys, :tagging_sorted, :tags_hash, :array_of_scores
  def initialize(query)
    @query = query
    @consumer_key = ENV['CONSUMERKEY']
    @consumer_secret = ENV['CONSUMERSECRET']
    # @consumer_key = "ybFtYnXXu3jaMbWyX49xFnnFo"
    # @consumer_secret = "loN3PdBiG7CfnQ5FqVVALLnCTdS9jEmIR9ocN1tE9q6HSQvElt"
  end

  def load_dictionary
    Sentimental.load_defaults
    @analyzer = Sentimental.new
  end

  def query
    @query
  end

  def sub!
    @query.gsub!(/#/, "\%23")
    @query.gsub!(/ /, "\%20")
  end

  def configure_twitter_client
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @consumer_key
      config.consumer_secret     = @consumer_secret
    end
  end

  def make_request
    @client.get("https://api.twitter.com/1.1/search/tweets.json?q=#{@query}&count=100" )
  end

  def re_sub!
    @query.sub!(/%23/, "\#")
    @query.sub!(/%20/, "\ ")
  end

  def get_tweet_array
    @tweets_collection = []
    result = self.make_request
    i = 0
    while i == 0
      @tweets_collection << @client.get("https://api.twitter.com/1.1/search/tweets.json?q=#{@query}&count=100#{result[:search_metadata][:next_results]}")
      i += 1
    end
    self.re_sub!
  end

  def get_text_array
    @tweets_status = []
    @tweets_collection.map do |tweets_hash|
      tweets_hash[:statuses].map {|status| @tweets_status << status [:text]}
    end
  end

  def tweets_array_constructor
    @tweets_text_array = []
    @tweets_status.each_with_index do |tweet, i|
      score = @analyzer.get_score(tweet)
      text = tweet
      id = i
      tweet = {
        :score => score,
        :id => id,
        :text => text
      }
      @tweets_text_array << tweet
    end
  end

  def construct_array_of_scores
    @array_of_scores = []
    @tweets_text_array.each do |tweet|
      @array_of_scores << tweet[:score]
    end
  end

  def construct_array_of_text
    @array_of_text = []
    @tweets_text_array.each do |tweet|
      @array_of_text << tweet[:text]
    end
    @array_of_text.join
  end

  def desc_statistics_init
    @stats = DescriptiveStatistics::Stats.new(@array_of_scores)
  end

  def statistic_mean
    @stats.mean
  end

  def statistic_kurtosis
    @stats.kurtosis
  end

  def statistic_relative_standard_deviation
    @stats.standard_deviation
  end

  def statistic_standard_deviation
    @stats.standard_deviation
  end

  def statistic_mode
    @stats.mode
  end

  def statistic_skewness
    @stats.skewness
  end

  def statistic_median
    @stats.median
  end

  def process_request
    self.load_dictionary
    self.sub!
    self.configure_twitter_client
    self.get_tweet_array
    self.get_text_array
    self.tweets_array_constructor
    self.construct_array_of_scores
    self.desc_statistics_init
    @results_hash = {
      :mean => self.statistic_mean,
      :median => self.statistic_median,
      :mode => self.statistic_mode,
      :rsd => self.statistic_relative_standard_deviation,
      :sd => self.statistic_standard_deviation,
      :kurtosis => self.statistic_kurtosis,
      :skewness => self.statistic_skewness
    }
  end


  def text_tagging
    self.load_dictionary
    self.sub!
    self.configure_twitter_client
    self.get_tweet_array
    self.get_text_array
    self.tweets_array_constructor
    @status_array = self.construct_array_of_text
    @tagging_hash = Indico.text_tags(@status_array)
  end

  def sort_text_tagging_hash
    @tagging_sorted = @tagging_hash.sort{ |a, b| b[1] <=> a[1]}
  end

  def return_top_three_tags
    self.text_tagging
    self.sort_text_tagging_hash
    @first_tag = @tagging_sorted[0][0]
    @second_tag = @tagging_sorted[1][0]
    @third_tag = @tagging_sorted[2][0]
    @tags_hash = {
      :first => @first_tag,
      :second => @second_tag,
      :third => @third_tag
    }
  end

  def manipulate_score(score)
    (score * 100) + 100
  end


end