require 'dotenv/load'
require 'amazon/ecs'

class App
  TARGET_NAME = 'Nintendo Switch'
  TARGET_ASINS = ['B01NCXFWIZ', 'B0725V538Z'].freeze
  BORDER_PRICE = 80000

  PRICE_XPATH = 'OfferSummary/LowestNewPrice/Amount'.freeze
  ITEM_NAME_XPATH = 'ItemAttributes/Title'.freeze
  DETAIL_PAGE_URL_XPATH = 'DetailPageURL'.freeze

  def initialize
    Amazon::Ecs::debug = ENV['mode'] == 'debug'
    Amazon::Ecs.configure do |options|
      options[:AWS_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
      options[:AWS_secret_key] = ENV['AWS_SECRET_KEY']
      options[:associate_tag] = ENV['AMAZON_ASSOCIATE_TAG']
    end
  end

  def response
    @response ||= Amazon::Ecs.item_search(TARGET_NAME, country: 'jp', search_index: 'All', response_group: "ItemAttributes, OfferSummary")
  end

  def target_items
    response.items.select { |item| TARGET_ASINS.include?(item.get('ASIN')) }
  end

  def met_items
    target_items.select { |item| item.get(PRICE_XPATH).to_i <= BORDER_PRICE }
  end
end

class Formatter
  def basic_info(item)
    puts "#{item.get(App::ITEM_NAME_XPATH)} 新品価格 #{item.get(App::PRICE_XPATH)}円"
  end

  def met_info(item)
    puts "#{item.get(App::ITEM_NAME_XPATH)}が#{item.get(App::PRICE_XPATH)}円で販売開始されました。=> #{item.get(App::DETAIL_PAGE_URL_XPATH)}"
  end
end


app = App.new
formatter = Formatter.new
begin
  app.target_items.each { |item| formatter.basic_info(item) }
  app.met_items.each { |item| formatter.met_info(item) }
rescue Amazon::RequestError
  puts 'request limit exceeded.'
end
