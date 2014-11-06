#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'uservoice-ruby'
require 'slop'

opts = Slop.parse do
  banner 'Usage: import.rb [options]'
  help
  
  on 'uservoice_domain='
  on 'uservoice_key='
  on 'uservoice_secret='
  on 'uservoice_forum_id=', 'Numerical ID of the forum to import suggestions from (extract from the URL in the admin UI)'
  
  
  
  on 'v', 'verbose', 'Enable verbose mode'
end

uservoice_client = UserVoice::Client.new(opts[:uservoice_domain], opts[:uservoice_key], opts[:uservoice_secret])

suggestions = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions")
puts "Suggestions to import: #{suggestions.size}" if opts[:verbose]

# Loops through all the suggestions and loads new pages as necessary.
suggestions.each do |suggestion|
  puts suggestion.inspect if opts[:verbose]
end