class SearchesController < ApplicationController
require 'csv'
  def new
    example_array = ["obamacare", "christmas", "The Graduate", "bunnies", "bacon", "puppies"]
    @example = example_array.sample
  end

  def show
    @query = params[:query]
    searcher = ApiSearcher.new(@query)
    stats_hash = searcher.process_request
    @score = searcher.manipulate_score(stats_hash[:mean])
    @sd = searcher.manipulate_sd(stats_hash[:sd])
    @words = stats_hash[:top_words]
    @convo1 = stats_hash[:convos][:first]
    @convo2 = stats_hash[:convos][:second]
    @convo3 = stats_hash[:convos][:third]

    @most_influential_icon = stats_hash[:most_influential].first[:profile_photo]
    @most_influential_user = stats_hash[:most_influential].first[:user_name]
    @most_influential_tweet = stats_hash[:most_influential].first[:text]

    respond_to do |format|
      format.html
      format.json { render :json => {
        query: @query,
        score: @score,
        sd: @sd,
        words: @words,
        convo1: @convo1,
        convo2: @convo2,
        convo3: @convo3,
        user_thumb: @most_influential_icon,
        username: @most_influential_user,
        tweet: @most_influential_tweet
        }}
    end

  end
end




