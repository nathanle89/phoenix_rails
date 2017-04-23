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

    # Compute authentication string required as part of the authentication
    # endpoint response. Generally the authenticate method should be used in
    # preference to this one
    #
    # @param socket_id [String] Each PhoenixRails socket connection receives a
    #   unique socket_id. This is sent from phoenix.js to your server when
    #   channel authentication is required.
    # @param custom_string [String] Allows signing additional data
    # @return [String]
    #
    def authentication_string(socket_id, custom_string = nil)
      validate_socket_id(socket_id)

      unless custom_string.nil? || custom_string.kind_of?(String)
        raise Error, 'Custom argument must be a string'
      end

      string_to_sign = [socket_id, name, custom_string].
        compact.map(&:to_s).join(':')
      PhoenixRails.logger.debug "Signing #{string_to_sign}"
      token = @client.authentication_token
      digest = OpenSSL::Digest::SHA256.new
      signature = OpenSSL::HMAC.hexdigest(digest, token.secret, string_to_sign)

      return "#{token.key}:#{signature}"
    end

    # Generate the expected response for an authentication endpoint.
    #
    # @example Private channels
    #   render :json => PhoenixRails['private-my_channel'].authenticate(params[:socket_id])
    #
    # @example Presence channels
    #   render :json => PhoenixRails['private-my_channel'].authenticate(params[:socket_id], {
    #     :user_id => current_user.id, # => required
    #     :user_info => { # => optional - for example
    #       :name => current_user.name,
    #       :email => current_user.email
    #     }
    #   })
    #
    # @param socket_id [String]
    # @param custom_data [Hash] used for example by private channels
    #
    # @return [Hash]
    #
    # @private Custom data is sent to server as JSON-encoded string
    #
    def authenticate(socket_id, custom_data = nil)
      custom_data = MultiJson.encode(custom_data) if custom_data
      auth = authentication_string(socket_id, custom_data)
      r = {:auth => auth}
      r[:channel_data] = custom_data if custom_data
      r
    end

    private

    def validate_socket_id(socket_id)
      unless socket_id && /\A\d+\.\d+\z/.match(socket_id)
        raise PhoenixRails::Error, "Invalid socket ID #{socket_id.inspect}"
      end
    end
  end
end
