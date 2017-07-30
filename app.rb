require 'dotenv/load'
require 'amazon/ecs'

class App
  TARGET_ASINS = ['B01NCXFWIZ'].freeze

  def initialize
    Amazon::Ecs::debug = ENV['DEBUG']
    Amazon::Ecs.configure do |options|
      options[:AWS_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
      options[:AWS_secret_key] = ENV['AWS_SECRET_KEY']
      options[:associate_tag] = ENV['AMAZON_ASSOCIATE_TAG']
    end
  end

  def response
    @response ||= Amazon::Ecs.item_search('Nintendo Switch', country: 'jp', search_index: 'All', response_group: "ItemAttributes, OfferSummary")
  end

  def target_items
    response.select { |item| TARGET_ASINS.include?(item.get('ASIN')) }
  end

  def price_xpath
    'OfferSummary/LowestNewPrice/Amount'
  end

  def item_name_xpath
    'ItemAttributes/Title'
  end

  def formatted
    target_items.each do |item|
      puts "#{item.get(item_name_xpath)} 新品価格 #{item.get(price_xpath)}円"
    end
  end
end
