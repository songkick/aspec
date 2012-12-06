require 'rubygems'
require 'sinatra'

class TestApp < Sinatra::Application
  get "/" do
  end

  get "/artists" do
    status 200
    content_type :json
    @@artists.to_json
  end

  post "/artists" do
    @@artists ||= []
    @@artists << params[:name]
    status 204
    nil
  end

  delete "/artists/:name" do
    @@artists = @@artists.reject {|a| a == params[:name] }
    status 204
    nil
  end
end

