require 'sinatra/base'
require 'centurion'

class Centurion
  class Server < Sinatra::Application

    get "/projects.json" do
      content_type "application/json"
      Centurion.db.collection_names
    end

    get "/projects/:id.json" do
      content_type "application/json"
      Centurion.db.collection(params[:id])
    end

    get "/favicon.ico" do
      ""
    end

  end
end
