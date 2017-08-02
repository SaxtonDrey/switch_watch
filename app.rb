require 'bundler/setup'
require 'dotenv/load'
require 'twitter'
require 'nokogiri'
require 'open-uri'

class App
  TARGET_ASINS = ['B01NCXFWIZ', 'B01N5QLLT3'].freeze
  BORDER_PRICE = 40000
  USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36'
  URL_BASE = 'https://www.amazon.co.jp/o/ASIN/'.freeze

  def exec
    opt = { 'User-Agent' => USER_AGENT }
    TARGET_ASINS.map do |asin|
      sleep(1)
      doc = Nokogiri::HTML(open(item_url(asin), opt))
      price = doc.css('#priceblock_ourprice').text.tr('￥,','').strip.to_i
      name = doc.css('#productTitle').text.strip
      { name: name, price: price, url: item_url(asin) }
    end
  end

  def item_url(asin)
    "#{URL_BASE}#{asin}"
  end
end

class Formatter
  def basic_info(item)
    "#{item[:name]} 新品価格 #{item[:price]}円"
  end

  def met_info(item)
    "#{item[:name]}が#{item[:price]}円で販売開始されました。=> #{item[:url]}"
  end
end

class Notifier
  attr_reader :client

  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
    end
  end

  def send(msg)
    @client.update("@#{ENV["TWITTER_ID"]} #{msg}")
  end
end

class Logger
  def log(msg)
    puts "#{msg} | ran at #{Time.now}"
  end
end


app = App.new
formatter = Formatter.new
notifier = Notifier.new
logger = Logger.new

logger.log("=======start======")
begin
  app.exec.each do |item|
    logger.log(formatter.basic_info(item))
    notifier.send(formatter.met_info(item)) if item[:price] < App::BORDER_PRICE
  end
rescue => e
  logger.log(e.message)
end
logger.log("=======end======")
