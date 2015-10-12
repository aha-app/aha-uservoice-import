# Import fom UserVoice to Aha!

This script will import the entire contents of a UserVoice portal into an 
Aha! product. This includes the ideas, users, votes and comments.

The script is written in Ruby and requires bundler.

Prepare for use:

    bundle
    
Invoke:

    ./import.rb
    
Usage:

    ./import.rb [options]
      --uservoice_domain    Uservoice domain
      --uservoice_key       Uservoice key
      --uservoice_secret    Uservoice secret
      --uservoice_forum_id  Numerical ID of the forum to import suggestions from (extract from the URL in the admin UI)
      --aha_domain          Aha domain
      --aha_email           Aha email
      --aha_password        Aha password
      --aha_product         Reference key for the product to create ideas in
      -v, --verbose         Enable verbose mode
      --help                
