require_relative "lib/hangman"
require "bundler/setup"

instance = Hangman.new
instance.run
