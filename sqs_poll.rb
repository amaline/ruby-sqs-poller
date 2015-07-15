#!/usr/local/bin/ruby

require 'aws-sdk'
require 'net/http'
require 'uri'
require 'json'

q	= "slack_receive_queue"
useast 	= "us-east-1"

if ENV['ROUTER_ENDPOINT'].nil?
  fail "ROUTER_ENDPOINT environmental variable must be set"
end

endpoint = URI.parse ENV['ROUTER_ENDPOINT']
#endpoint = URI.parse "http://requestb.in/108ulae1"


if ENV['AWS_REGION'].nil?
	ENV['AWS_REGION'] = useast
end

sqs = Aws::SQS::Client.new
resp =sqs.list_queues()


url = resp.queue_urls.find{ |i| i =~ /#{q}$/ }

poller = Aws::SQS::QueuePoller.new(url)
poller.poll do |msg|

 parsed = JSON.parse(msg.body)

 #if parsed["channel_name"] != "chatops"
   #next #skip non chatops channels
 #end

 puts "id	 = #{parsed['user_id']}"
 puts "message   = #{parsed['text']}"

 # no infinite loops of messages by filtering user_id for USLACKBOT
 # only messages that begin with %% will be considered commands

 if parsed["user_id"] != "USLACKBOT"


   http = Net::HTTP.new(endpoint.host,endpoint.port)

   if endpoint.scheme == "https"
      http.use_ssl = true
      http.ssl_version = :TLSv1
   end

   req = Net::HTTP::Post.new(endpoint.request_uri)
   req.body=msg.body
   
   req["Content-Type"] = 'application/json'

   if ! ENV['X_AUTH_TOKEN'].nil?
        puts "setting auth token to #{ENV['X_AUTH_TOKEN']}"
	req["X-Auth-Token"] = ENV['X_AUTH_TOKEN']
   end

   resp=http.request(req)
   case resp
      when Net::HTTPSuccess
         puts "message forwarded [ #{parsed['text']} ]"
      else
         fail "There was an error when posting #{msg.body}, the error was #{resp.body}"
   end 
 end

end
