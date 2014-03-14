# further requires (models, helpers, core extensions etc. { but not 'middleware' because that should be grabbed up by Rack when appropriate })
Dir.glob('./application/**/*.rb') do |file|
  require file.gsub(/\.rb/, '') unless file.include?('middleware')
end

require 'pp'
require 'mysql2'
require 'json'
require 'date'
require 'sinatra/cross_origin'

# -------------------------------------------------------------------

#session[:request_db_session] =
#session[:authorized_db_session] = db_session.serialize
#session[:authorized_db_session].delete

SERVER_KEY='wqqryyhbifqtdzirlscpxkdubwamgnnqlpujwcvdrijkgdjyxn'

configure do
  enable :cross_origin
  set :protection, :except => :http_origin 
	set :allow_origin, "*"
	set :allow_methods, [:get, :post, :options]
	set :allow_credentials, true
	#set :max_age, "1728000"  
end

before do
  if request.request_method == "POST"
    body_parameters = request.body.read
    begin	
    	params.merge!(JSON.parse(body_parameters))
  	rescue
  		return true
  	end
  end
end


get '/' do

	"testing mtr server endpoint"

end


#import the mtr report data into the database
post '/processreport' do
	puts 'processreport route'

	puts "params: #{params}"

	server_key = params['server_key']
	report_data_line = params['report_data_line']
	
	puts "server key is: #{server_key}"

	begin
		if (server_key == SERVER_KEY) then
		
			#process data
			puts "report data line incoming:"
			puts report_data_line
			result_array = report_data_line.split(/\s+/)
			
			result_array.each_with_index do |item,i|
				puts "#{i}: #{item}"
			end




			"{\"status\":true}"
		else
			html_page("Access Denied","")
		end
	
	rescue
# 		"#{callback}({})"
		"{}" #POST MOD
	end
	
end


def html_page(title, body)
    "<html>" +
        "<head><title>#{h title}</title></head>" +
        "<body><h1>#{h title}</h1>#{body}</body>" +
    "</html>"
end

helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

