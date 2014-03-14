#############################################
#ruby script to act as mtr client, sending
#mtr reports to sinatra-based server
#############################################

#script settings
#host_url='http://foxtrot.orangeblueprint.com/processreport'
host_url='http://localhost:3000/processreport'
server_key='wqqryyhbifqtdzirlscpxkdubwamgnnqlpujwcvdrijkgdjyxn'


#write report to file
`mtr --report #{ARGV[0]} > ./report_result.txt` 
#`echo "test2 data" > ./report_result.txt` 

#read file into variable
text=File.open('./report_result.txt').read
text.each_line do |report_data_line|

	#remove line endings
	report_data_line.gsub!(/\r|\n/, '')

	#send report line to sinatra-based server for processing

	cmd = "
	/usr/bin/curl -X POST \
	-H \"Content-Type: application/json\" \
	--data '{\"server_key\":\"#{server_key}\",\"report_data_line\":\"#{report_data_line}\"}' \
	#{host_url}
	"

	puts "CURL CMD #{cmd}" 
	curl_result = `#{cmd} 2>&1`  	
	puts "\n--------- curl cmd output ---------\n\n #{curl_result} \n------------------- \n"

end




