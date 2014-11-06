#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'uservoice-ruby'
require 'aha-api'
require 'slop'
require 'active_support/core_ext'


#
# Convert plain text to HTML. From ActionView.
#
def simple_format(text, html_options = {}, options = {})
  paragraphs = split_paragraphs(text)

  if paragraphs.empty?
    "<p></p>"
  else
    paragraphs.map! { |paragraph|
      "<p>#{paragraph}</p>"
    }.join("\n\n").html_safe
  end
end
def split_paragraphs(text)
  return [] if text.blank?

  text.to_str.gsub(/\r\n?/, "\n").split(/\n\n+/).map! do |t|
    t.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') || t
  end
end

def import(opts)
  uservoice_client = UserVoice::Client.new(opts[:uservoice_domain], opts[:uservoice_key], opts[:uservoice_secret])
  aha_client = AhaApi::Client.new(domain: opts[:aha_domain], url_base: "http://lvh.me:3000/", login: opts[:aha_email], password: opts[:aha_password])

  suggestions = uservoice_client.get_collection("/api/v1/forums/#{opts[:uservoice_forum_id]}/suggestions")
  puts "Suggestions to import: #{suggestions.size}" if opts[:verbose]

  # Loops through all the suggestions, creating new ideas in Aha! as it goes.
  suggestions.each do |suggestion|
    puts suggestion.inspect if opts[:verbose]
  
    aha_client.create_idea(opts[:aha_product], suggestion['title'], simple_format(suggestion['text']))
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