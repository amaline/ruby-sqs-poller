#!/usr/local/bin/ruby

require 'aws-sdk'
require 'net/http'
require 'uri'
require 'json'

endpoint = URI.parse "https://hooks.slack.com/services/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"
#endpoint = URI.parse "http://requestb.in/108ulae1"

q="slack_receive_queue"
useast = "us-east-1"
ENV['AWS_REGION'] = useast

sqs = Aws::SQS::Client.new
resp =sqs.list_queues()


url = resp.queue_urls.find{ |i| i =~ /#{q}$/ }

poller = Aws::SQS::QueuePoller.new(url)
poller.poll do |msg|

 parsed = JSON.parse(msg.body)

 if parsed["channel_name"] != "chatops"
   next #skip non chatops channels
 end

 puts "id	 = #{parsed['user_id']}"
 puts "message   = #{parsed['text']}"

 # no infinite loops of messages by filtering user_id for USLACKBOT
 # only messages that begin with %% will be considered commands

 if parsed["user_id"] != "USLACKBOT" && parsed["text"] =~ /^%%/	

   payload={"text":"message received {#{parsed['text']}}"}

   http = Net::HTTP.new(endpoint.host,endpoint.port)
   http.use_ssl = true
   http.ssl_version = :TLSv1

   req = Net::HTTP::Post.new(endpoint.request_uri)
   req.set_form_data ( {"payload" => payload.to_json } )
   req["Content-Type"] = 'application/x-www-form-urlencoded'

   resp=http.request(req)
   case resp
      when Net::HTTPSuccess
         puts "acknowledgement sent"
      else
         fail "There was an error when posting #{payload}, the error was #{resp.body}"
   end 
 end

end
