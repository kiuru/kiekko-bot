require 'socket'
require './conf.rb'

class KiekkoBot

  def initialize(host, port)

    connect(host, port)
    login
    listen

  end
 
  def connect(host, port)

    puts "DEBUG | Open conenction"
    @server = TCPSocket.open(host, port, 30)

  end

  def login

    puts "DEBUG | Login"
    @server.write "V#{SERVER_VERSION}\n" # Hello server (version number)
    sleep 1
    @server.write "z0,/authxx #{KIEKKO_USER} #{KIEKKO_PASS}\n" # Login user
    sleep 1
    @server.write "E#{SERVICE_USER},#{SERVICE_PASS}\n" # Login service user
    sleep 1
    @server.write "e0\n" # ignore spectators off

  end

  def listen

    loop do

      puts "DEBUG | Listen server"
      i = 0

      until @server.eof?
        begin
          response = @server.read_nonblock(1024)
          puts "RESPONSE MSG: #{response}"

          # Should be? -> /K\*(.*)\*/ K-tag miss sometimes
          if response =~ /K\*(.*)\*/ then
            sender = response[/K\*(.*)\*/,1]
            puts "Msg: *#{sender}*"
            @server.write "z0,/msg #{sender} Hello #{sender}!\r\n"
          end

          # I don't know yet how do keepalive to right
          if (i % 2) == 0
            @server.write "p0\n"
            #puts "DEBUG - KEEPALIVE"
          end

          i=i+1
        rescue IO::IOError
          puts "ERROR"
        end
      end

      puts "DEBUG | Connection lost"
      @server.close
      puts "DEBUG | Begin reconnect after 30 sec"
      sleep 30
      connect
      login

    end

  end
  
end

KiekkoBot.new(HOSTNAME, PORT_NUMBER)