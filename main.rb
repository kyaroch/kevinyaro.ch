require "sinatra/base"
require "sinatra/contrib/all"
require "securerandom"
require "mail"

class HomePage < Sinatra::Base
  register Sinatra::Contrib

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
      name, email, mail_subj, message = info
      begin
        file_subj = mail_subj.dup
        if File.exist?("messages/#{file_subj}") || file_subj.empty?
          file_subj << SecureRandom.hex
        end
        File.open("messages/#{file_subj}", "w") do |file|
          file << "Name: #{name}\n"
          file << "Email: #{email}\n"
          file << "Time: #{Time.now.getutc}\n\n"
          file << message
        end
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace.inspect
        #Error not made apparent to user
      end
      begin
        #Server SSL cert not valid for 'localhost'
        #I could probably fix this, but the server doesn't need SSL to submit mail to itself
        Mail.defaults do
          delivery_method :smtp, { :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE }
        end

        Mail.deliver do
          from 'www-data@kevinyaro.ch'
          to 'kjyaroch@gmail.com'
          subject mail_subj
          body "From: #{email}\n\n#{message}"
        end
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace.inspect
        return :failure #Displays nonspecific error message to user; see view
      end
      :success
    end
  end

  #Is there a way to route all these static pages in the same block? Probably. I should find out how.
  get '/' do
    erb :index, :layout => :layout
  end

  not_found do
    erb :notfound, :layout => :layout
  end

  get '/links' do
    erb :links, :layout => :layout
  end

  get '/contact' do
    erb :contact, :layout => :layout
  end

  get '/gallery' do
    erb :gallery, :layout => :layout
  end

  post '/contact' do
    info = params[:sender_name], params[:sender_email], params[:subject], params[:message]
    @sent = record_message(info)
    @name, @email, @subject, @message = info if @sent == :failure #If message not sent, user doesn't lose whatever they typed
    erb :contact, :layout => :layout
  end

  get '/index' do
    redirect to('/')
  end

end
