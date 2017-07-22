module PhoenixRails
  class Client
    attr_accessor :scheme, :host, :port, :secret, :key
    attr_writer :connect_timeout, :send_timeout, :receive_timeout, :keep_alive_timeout


    def initialize(options = {})
      options = {
        :scheme => 'http',
        :port => 80,
      }.merge(options)
      @scheme, @host, @port, @secret, @key = options.values_at(
        :scheme, :host, :port, :secret, :key
      )

      # Default timeouts
      @connect_timeout = 5
      @send_timeout = 5
      @receive_timeout = 5
      @keep_alive_timeout = 30
    end

    def url(path=nil)
      URI::Generic.build({
        :scheme => @scheme,
        :host => @host,
        :port => @port,
        :path => "/api/realtime#{path}"
      })
    end

    def encrypted=(boolean)
      @scheme = boolean ? 'https' : 'http'
      # Configure port if it hasn't already been configured
      @port = boolean ? 443 : @port
    end

    def encrypted?
      @scheme == 'https'
    end

    def timeout=(value)
      @connect_timeout, @send_timeout, @receive_timeout = value, value, value
    end

    def resource(path)
      Resource.new(self, path)
    end

    def get(path, params = {})
      Resource.new(self, path).get(params)
    end

    def post(path, params = {})
      Resource.new(self, path).post(params)
    end

    def channel(channel_name)
      raise ConfigurationError, 'Missing client configuration: please check that secret is configured.' unless configured?
      Channel.new(url, channel_name, self)
    end

    alias :[] :channel

    def channels(params = {})
      get('/channels', params)
    end

    def trigger(channels, event_name, data, params = {})
      post('/events', trigger_params(channels, event_name, data, params))
    end

    # @private Construct a net/http http client
    def http_client
      @client ||= begin
        require 'httpclient'

        HTTPClient.new.tap do |c|
          c.connect_timeout = @connect_timeout
          c.send_timeout = @send_timeout
          c.receive_timeout = @receive_timeout
          c.keep_alive_timeout = @keep_alive_timeout
        end
      end
    end

    def generate_authentication_token(claim = {})
      claim.merge!({ key: @key })

      JWT.encode claim, @secret, 'HS256'
    end

    private

    def trigger_params(channels, event_name, data, params)
      channels = Array(channels).map(&:to_s)
      raise PhoenixRails::Error, "Too many channels (#{channels.length}), max 10" if channels.length > 10

      case data
        when String
          encoded_data =  data
        else
          begin
            encoded_data = MultiJson.encode(data)
          rescue MultiJson::DecodeError => e
            PhoenixRails.logger.error("Could not convert #{data.inspect} into JSON")
            raise e
          end
      end

      params.merge({
        :name => event_name,
        :channels => channels,
        :data => encoded_data
      })
    end

    def configured?
      host && scheme && secret && key
    end

  end
end

