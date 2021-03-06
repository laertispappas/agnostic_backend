require 'faraday'

module AgnosticBackend
  module Elasticsearch

    class Client
      attr_reader :endpoint

      def initialize(endpoint:)
        @endpoint = endpoint
        @connection = Faraday::Connection.new(url: endpoint)
      end

      # returns an array of RemoteIndexFields (or nil)
      def describe_index_fields(index_name, type)
        response = send_request(:get, path: "#{index_name}/_mapping/#{type}")
        if response.success?
          body = ActiveSupport::JSON.decode(response.body) if response.body.present?
          return if body.blank?
          fields = body[index_name.to_s]["mappings"][type.to_s]["properties"]

          fields.map do |field_name, properties|
            properties = Hash[ properties.map{|k,v| [k.to_sym, v]} ]
            type = properties.delete(:type)
            AgnosticBackend::Elasticsearch::RemoteIndexField.new field_name, type, **properties
          end
        end
      end

      # sends an HTTP request to the ES server
      # @body is taken to be either
      # (a) a Hash (in which case it will be encoded to JSON), or
      # (b) a string (in which case it will be assumed to contain JSON data)
      # returns a Faraday::Response instance
      def send_request(http_method, path: "", body: nil)
        body = ActiveSupport::JSON.encode(body) if body.is_a? Hash
        @connection.run_request(http_method.downcase.to_sym,
                                path.to_s,
                                body,
                                default_headers)
      end

      private

      def default_headers
        {'Content-Type' => 'application/json'}
      end
    end
  end
end
