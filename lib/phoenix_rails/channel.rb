require 'openssl'
require 'multi_json'

module PhoenixRails
  # Trigger events on Channels
  class Channel
    attr_reader :name
    INVALID_CHANNEL_REGEX = /[^A-Za-z0-9_\-=@,.;]/
    def initialize(base_url, name, client = PhoenixRails)
      @uri = base_url.dup
      if PhoenixRails::Channel::INVALID_CHANNEL_REGEX.match(name)
        raise PhoenixRails::Error, "Illegal channel name '#{name}'"
      end
      @uri.path = @uri.path + "/channels/#{name}/"
      @name = name
      @client = client
    end

    # Trigger event
    def trigger!(event_name, data, socket_id = nil)
      params = {}
      if socket_id
        validate_socket_id(socket_id)
        params[:socket_id] = socket_id
      end
      @client.trigger(name, event_name, data, params)
    end

    # Trigger event, catching and logging any errors.
    def trigger(event_name, data, socket_id = nil)
      trigger!(event_name, data, socket_id)
    rescue PhoenixRails::Error => e
      PhoenixRails.logger.error("#{e.message} (#{e.class})")
      PhoenixRails.logger.debug(e.backtrace.join("\n"))
    end

    # Request users for a presence channel
    # Only works on presence channels (see: http://PhoenixRails.com/docs/client_api_guide/client_presence_channels and https://PhoenixRails.com/docs/rest_api)
    #
    # @example Response
    #   [{"id"=>"4"}]
    #
    # @return [Hash] Array of user hashes for this channel
    # @raise [PhoenixRails::Error] on invalid PhoenixRails response - see the error message for more details
    # @raise [PhoenixRails::HTTPError] on any error raised inside Net::HTTP - the original error is available in the original_error attribute
    #
    def users
      @client.get("/channels/#{name}/users")[:users]
    end

    private

    def validate_socket_id(socket_id)
      unless socket_id && /\A\d+\.\d+\z/.match(socket_id)
        raise PhoenixRails::Error, "Invalid socket ID #{socket_id.inspect}"
      end
    end
  end
end
