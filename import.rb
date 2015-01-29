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
    
    last_name, first_name = *user['user']['name'].reverse.split(/\s+/, 2).collect(&:reverse)
    
    begin
      response = aha_client.post("/api/v1/products/#{opts[:aha_product]}/portal_users", portal_user: {email: user['user']['email'], first_name: first_name, last_name: last_name})
      puts response
    rescue
    end
    
    idea_created = aha_client.post("/api/v1/products/#{opts[:aha_product]}/ideas", idea: {name: suggestion['title'], description: suggestion['formatted_text'],
      created_by_portal_user: user['user']['email']})
    puts idea_created.inspect
      
    comments = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions/#{suggestion['id']}/comments?per_page=500")
    comments.each do |comment|
      puts comment.inspect
      
      comment_user = uservoice_client.get("/api/v1/users/#{comment['creator']['id']}.json")
      last_name, first_name = *comment_user['user']['name'].reverse.split(/\s+/, 2).collect(&:reverse)
    
      begin
        response = aha_client.post("/api/v1/products/#{opts[:aha_product]}/portal_users", portal_user: {email: comment_user['user']['email'], first_name: first_name, last_name: last_name})
        puts response
      rescue
      end
      
      aha_client.post("api/v1/ideas/#{idea_created['idea']['id']}/idea_comments", idea_comment: {body: comment['formatted_text'], portal_user: comment_user['user']['email']})
    end
    
    supporters = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions/#{suggestion['id']}/supporters?per_page=500")
    supporters.each do |supporter|
      puts supporter.inspect
      
      vote_user = uservoice_client.get("/api/v1/users/#{supporter['user']['id']}.json")
      last_name, first_name = *vote_user['user']['name'].reverse.split(/\s+/, 2).collect(&:reverse)
    
      begin
        response = aha_client.post("/api/v1/products/#{opts[:aha_product]}/portal_users", portal_user: {email: vote_user['user']['email'], first_name: first_name, last_name: last_name})
        puts response
      rescue
      end
      
      aha_client.post("api/v1/ideas/#{idea_created['idea']['id']}/endorsements", idea_endorsement: {email: vote_user['user']['email']})
    end
  end

end


opts = Slop.parse do |o|
  o.string '--uservoice_domain', 'Uservoice domain'
  o.string '--uservoice_key', 'Uservoice key'
  o.string '--uservoice_secret', 'Uservoice secret'
  o.string '--uservoice_forum_id', 'Numerical ID of the forum to import suggestions from (extract from the URL in the admin UI)'
  
  o.string '--aha_domain', 'Aha domain'
  o.string '--aha_email', 'Aha email'
  o.string '--aha_password', 'Aha password'
  o.string '--aha_product', 'Reference key for the product to create ideas in'

  o.bool '-v', '--verbose', 'Enable verbose mode'
  
  o.on '--help' do
    puts o
    exit
  end
end


import(opts)