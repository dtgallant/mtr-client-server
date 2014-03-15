# further requires (models, helpers, core extensions etc. { but not 'middleware' because that should be grabbed up by Rack when appropriate })
Dir.glob('./application/**/*.rb') do |file|
  require file.gsub(/\.rb/, '') unless file.include?('middleware')
end

require 'pp'
require 'mysql2'
require 'json'
require 'date'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'yaml'

require_relative './models/models.rb'

#require_relative './settings.rb' #config
DB_CONFIG = YAML::load(File.open('config/database.yml'))
set :database, "mysql2://#{DB_CONFIG['username']}:#{DB_CONFIG['password']}@#{DB_CONFIG['host']}:#{DB_CONFIG['port']}/#{DB_CONFIG['database']}"

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

#produce a useful graph of the data
get '/graph' do

	@hops= HopRecord.all


	erb :graph
end

#import the mtr report data into the database
post '/processreport' do
	puts 'processreport route'

	puts "params: #{params}"

	server_key = params['server_key']
	report_data_line = params['report_data_line']
	group_code = params['group_code']
	host_requested = params['host_requested']

	sql_hop_records="INSERT INTO hop_records (group_code,host_requested,hop_number,hop_host,packet_loss,num_packets_sent,
		last_packet_latency,avg_packet_latency,best_packet_latency,worst_packet_latency,standard_deviation,created_at) 
			VALUES " # ( ?,?,?,?,?,?,?,?,?,?,?,?,? )"

	puts "#{@db_host}|#{@db_user}|#{@db_pass}|#{@db_name}"

	@db_host='localhost'
	@db_user='root'
	@db_pass=''
	@db_name='mtr_db'

	begin
		# connect to the MySQL server
		dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)
		
		if (server_key == SERVER_KEY) then
		
			#process data
			r = report_data_line.split(/\s+/)
	
			r.each_with_index do |item,i|
				puts "#{i}: #{item}"
			end
			
			#bypass the first line of the report, all others go in db		
			if (r[0].match('HOST:')==nil && r[0].match('Start:')==nil) then
				hop_number = r[1].gsub!(/\D/,'') #remove excess chars
				hop_host = r[2]
				packet_loss = r[3]
				num_packets_sent = r[4]
				last_packet_latency = r[5]
				avg_packet_latency = r[6]
				best_packet_latency = r[7]
				worst_packet_latency = r[8]
				standard_deviation = r[9]

				t = Time.now
				
				dbh.query(sql_hop_records + "('#{group_code}','#{host_requested}','#{hop_number}','#{hop_host}','#{packet_loss}','#{num_packets_sent}','#{last_packet_latency}','#{avg_packet_latency}','#{best_packet_latency}','#{worst_packet_latency}','#{standard_deviation}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
				
				
			end
				
			"{\"status\":true}"
		else
			html_page("Access Denied","")
		end
	
	rescue Mysql2::Error => e
		puts "Error code: #{e.errno}"
		puts "Error message: #{e.error}"
		puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	ensure
		# disconnect from server
		dbh.close if dbh
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

