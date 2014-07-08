require "sinatra"
require "sinatra/content_for"

helpers do
  def get_title(name)
    base_title = "kevinyaro.ch"
    if name.empty?
      base_title
    else
      "#{base_title} | #{name}"
    end
  end
end

get '/' do
  erb :index, :layout => :layout
end
