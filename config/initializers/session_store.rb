# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_glsamaker_session',
  :secret      => '2501f0c5921570d17b2b6d3094a3f7f933615d70527d9831591e6eae118ef556086ad2afc68f0af79c3c2e5fbf440008696f47a85eb3480bc7c12bf83a4c6492'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
