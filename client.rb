require 'socket'
require './conf.rb'
require './kiekko_bot.rb'

KiekkoBot.new(HOSTNAME, PORT_NUMBER)