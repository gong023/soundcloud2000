require 'net/http'
require 'json'
require 'soundcloud'

module Soundcloud2000
  class Client
    DEFAULT_LIMIT = 50

    attr_reader :client_id

    def initialize(client_id)
      @client_id = client_id
    end

    def tracks(page = 1, limit = DEFAULT_LIMIT)
      if File.exist?(AUTH_FILE)
        auth_file = JSON.parse(File.open(AUTH_FILE).read)
        client = ::SoundCloud.new(access_token: auth_file['access_token'])
        client.get('/me/activities', offset: (page - 1) * limit, limit: limit).to_json
      else
        get('/tracks', offset: (page - 1) * limit, limit: limit)
      end
    end

    def resolve(permalink)
      res = get('/resolve', url: "http://soundcloud.com/#{permalink}")
      if location = res['location']
        get URI.parse(location).path
      end
    end

    def uri_escape(params)
      URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
    end

    def request(type, path, params={})
      params[:client_id] = client_id
      params[:format] = 'json'

      req = if type == :post
              _p = Net::HTTP::Post.new("#{path}?#{uri_escape params}")
              _p.set_form_data(params)
              _p
            else
              Net::HTTP::Get.new("#{path}?#{uri_escape params}")
            end

      Net::HTTP.start('api.soundcloud.com', 443, :use_ssl => true) do |http|
        http.request(req)
      end
    end

    def get(path, params={})
      JSON.parse(request(:get, path, params).body)
    end

    def post(path, params={})
      JSON.parse(request(:post, path, params).body)
    end

    def location(url)
      uri = URI.parse(url)
      res = request(:get, uri.path)
      if res.code == '302'
        res.header['Location']
      end
    end

  end
end
