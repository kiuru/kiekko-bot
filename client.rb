require 'socket'
require 'json'
require 'httparty'
require './conf.rb'
require './kiekko_bot.rb'

KiekkoBot.new(HOSTNAME, PORT_NUMBER, true)