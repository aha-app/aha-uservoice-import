#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'uservoice-ruby'
require 'aha-api'
require 'slop'

def import(opts)
  uservoice_client = UserVoice::Client.new(opts[:uservoice_domain], opts[:uservoice_key], opts[:uservoice_secret])
  aha_client = AhaApi::Client.new(domain: opts[:aha_domain], url_base: "http://lvh.me:3000/", login: opts[:aha_email], password: opts[:aha_password])

  suggestions = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions")
  puts "Suggestions to import: #{suggestions.size}" if opts[:verbose]

  # Loops through all the suggestions, creating new ideas in Aha! as it goes.
  suggestions.each do |suggestion|
    puts suggestion.inspect if opts[:verbose]
    
    # Fetch the email address for the user.
    user = uservoice_client.get("/api/v1/users/#{suggestion['creator']['id']}.json")
    
    response = aha_client.create_idea(opts[:aha_product], suggestion['title'], suggestion['formatted_text'],
      "created_by_portal_user" => user['user']['email'])
    puts response.inspect
      
    comments = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions/#{suggestion['id']}/comments")
    comments.each do |comment|
      puts comment.inspect
      
      comment_user = uservoice_client.get("/api/v1/users/#{comment['creator']['id']}.json")
      aha_client.post("api/v1/ideas/#{response.idea.id}/idea_comments", body: comment['formatted_text'], portal_user: {email: comment_user['user']['email']})
    end
    
  end

end


opts = Slop.parse do
  banner 'Usage: import.rb [options]'
  help
  
  on 'uservoice_domain='
  on 'uservoice_key='
  on 'uservoice_secret='
  on 'uservoice_forum_id=', 'Numerical ID of the forum to import suggestions from (extract from the URL in the admin UI)'
  
  on 'aha_domain='
  on 'aha_email='
  on 'aha_password='
  on 'aha_product=', 'Reference key for the product to create ideas in'
  
  on 'v', 'verbose', 'Enable verbose mode'
end

import(opts)