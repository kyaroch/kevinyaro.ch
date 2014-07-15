require "sinatra/base"
require "sinatra/contrib/all"
require "securerandom"
require "mail"
require "yaml"

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
    
    def get_img_links(pairs, current)
      max = pairs.keys.max
      prev_img = current == 0 ? max : current - 1
      next_img = current == max ? 0 : current + 1
      return [prev_img, next_img]
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

  get '/' do
    erb :index, :layout => :layout
  end

  not_found do
    erb :notfound, :layout => :layout
  end

  post '/contact' do
    info = params[:sender_name], params[:sender_email], params[:subject], params[:message]
    @sent = record_message(info)
    @name, @email, @subject, @message = info if @sent == :failure #If message not sent, user doesn't lose whatever they typed
    erb :contact, :layout => :layout
  end
  
  get '/gallery' do
    redirect '/gallery/0'
  end
  
  get '/gallery/:id' do
    File.open('public/gallery.yaml') do |img_data|
      img_num = params[:id].to_i
      pairs = YAML.load(img_data)
      @image = pairs[img_num]['image']
      @caption = pairs[img_num]['caption']
      @prev_img, @next_img = get_img_links(pairs, img_num)
      erb :gallery, :layout => :layout
    end
  end
  
  get '/*' do
    viewname = params[:splat].first
    if File.exists?("views/#{viewname}.erb")
      erb viewname.to_sym, :layout => :layout
    else
      not_found
    end
  end
  
end
