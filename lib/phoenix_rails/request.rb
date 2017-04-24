require 'signature'
require 'digest/md5'
require 'multi_json'

module PhoenixRails
  class Request
    attr_reader :body, :params

    def initialize(client, verb, uri, params, body = nil)
      @client, @verb, @uri = client, verb, uri
      @head = {}

      @body = body
      if body
        params[:body_md5] = Digest::MD5.hexdigest(body)
        @head['Content-Type'] = 'application/json'
      end

      request = Signature::Request.new(verb.to_s.upcase, uri.path, params)
      request.sign(client.authentication_token)
      @params = request.signed_params
    end

    def send
      http = @client.http_client

      begin
        response = http.request(@verb, @uri, @params, @body, @head)
      rescue HTTPClient::BadResponseError, HTTPClient::TimeoutError,
        SocketError, Errno::ECONNREFUSED => e
        error = PhoenixRails::HTTPError.new("#{e.message} (#{e.class})")
        error.original_error = e
        raise error
      end

      body = response.body ? response.body.chomp : nil

      handle_response(response.code.to_i, body)
    end

    private

    def handle_response(status_code, body)
      case status_code
        when 200
          return symbolize_first_level(MultiJson.decode(body))
        when 400
          raise Error, "Bad request: #{body}"
        when 401
          raise AuthenticationError, body
        when 404
          raise Error, "404 Not found (#{@uri.path})"
        else
          raise Error, "Unknown error (status code #{status_code}): #{body}"
      end
    end

    def symbolize_first_level(hash)
      hash.inject({}) do |result, (key, value)|
        result[key.to_sym] = value
        result
      end
    end
  end
end
