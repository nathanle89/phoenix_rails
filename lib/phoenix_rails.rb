module PhoenixRails
  class Error < RuntimeError; end
  class AuthenticationError < Error; end
  class ConfigurationError < Error; end
  class HTTPError < Error; attr_accessor :original_error; end

  class << self
    extend Forwardable

    def_delegators :default_client, :scheme, :host, :port, :key, :secret
    def_delegators :default_client, :scheme=, :host=, :port=, :key=, :secret=

    def_delegators :default_client, :authentication_token, :url
    def_delegators :default_client, :encrypted=, :url=
    def_delegators :default_client, :timeout=, :connect_timeout=, :send_timeout=, :receive_timeout=, :keep_alive_timeout=

    def_delegators :default_client, :get, :post
    def_delegators :default_client, :channels, :trigger
    def_delegators :default_client, :channel, :[]

    def logger
      @logger ||= begin
        log = Logger.new($stdout)
        log.level = Logger::INFO
        log
      end
    end

    def default_client
      @default_client ||= PhoenixRails::Client.new
    end
  end

  if ENV['PHOENIX_RAILS_URL']
    self.url = ENV['PHOENIX_RAILS_URL']
  end
end

require 'phoenix_rails/channel'
require 'phoenix_rails/request'
require 'phoenix_rails/resource'
require 'phoenix_rails/client'
