require "sinatra"
require "sinatra/content_for"
require "securerandom"

helpers do
  def get_title(name)
    base_title = "kevinyaro.ch"
    if name.empty?
      base_title
    else
      "#{base_title} | #{name}"
    end
  end
  
  def record_message(info)
    name, email, subject, message = info
    begin
      file_subj = subject.dup
      if File.exist?("messages/#{subject}") || subject.empty?
        file_subj << SecureRandom.hex
      end
      File.open("messages/#{file_subj}", "w") do |file|
        file << "Name: #{name}\n"
        file << "Email: #{email}\n"
        file << "Time: #{Time.now.getutc}\n"
        file << message
      end
      :success
    rescue
      :failure
    end
  end
end

get '/' do
  erb :index, :layout => :layout
end

get '/links' do
  erb :links, :layout => :layout
end

get '/contact' do
  erb :contact, :layout => :layout
end

post '/contact' do
  info = params[:sender_name], params[:sender_email], params[:subject], params[:message]
  @sent = record_message(info)
  @name, @email, @subject, @message = info if @sent == :failure
  erb :contact, :layout => :layout
end

get '/index' do
  redirect to('/')
end
