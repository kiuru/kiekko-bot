class KiekkoBot

  private
  attr_accessor :host, :port, :is_admin, :server

  def initialize(host, port, admin = false)

    self.host = host
    self.port = port
    self.is_admin = admin
    connect
    login
    listen
  end
 
  def connect

    puts "DEBUG | Open conenction"
    @server = TCPSocket.open(host, port, 30)

  end

  def login

    puts "DEBUG | Login"
    @server.write "V#{SERVER_VERSION}\n" # Hello server (version number)
    sleep 1
    if is_admin
      @server.write "z0,/authxx #{KIEKKO_USER} #{KIEKKO_PASS}\n" # Login user
      sleep 1
    end
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
          puts "RESPONSE MSG: #{response.inspect}"

          methods(response)

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

  def methods(data)

    # Should be? -> /K\*(.*)\*/ K-tag miss sometimes
    # if data =~ /K\*(.*)\*/ then
    #   sender = data[/K\*(.*)\*/,1]
    #   message = data[/K\*(.*)\*(.*)/,2].strip
    #   puts "Msg: *#{sender}* #{message}"
    #   @server.write "z0,/msg #{sender} Hello #{sender}!\r\n"
    # end

    if data =~ /!hello/ then
      sender = data[/\*(.*)\* !hello/,1]
      puts "Command !hello: *#{sender}*"
      @server.write "z0,/msg #{sender} Hello #{sender}!\r\n"
    end

    if data =~ /!spect (.*)/ then
      sender = data[/\*(.*)\* !spect/,1]
      room = data[/!spect (.*)/,1].strip
      puts "Command *#{sender}* !spect #{room}"
      @server.write "z0,/s #{room}\r\n"
    end

    if data =~ /!join (.*)/ then
      sender = data[/\*(.*)\* !join/,1]
      room = data[/!join (.*)/,1].strip
      puts "Command *#{sender}* !join #{room}"
      @server.write "z0,/j #{room}\r\n"
    end

    if data =~ /!leave/ then
      sender = data[/\*(.*)\* !leave/,1]
      puts "Command *#{sender}* !leave"
      @server.write "z0,/leave\r\n"
    end

    if data =~ /!whois (.*)/ then
      sender = data[/\*(.*)\* !whois/,1]
      player = data[/!whois (.*)/,1].strip
      puts "Command *#{sender}* !whois #{player}"
      @server.write "z0,/whois #{player}\r\n"
    end

    if data =~ /!new/ && is_admin then
      sender = data[/\*(.*)\* !new/,1]
      puts "Command *#{sender}* !new"
      Thread.new {
        Kiekkobot.new(HOSTNAME, PORT_NUMBER)
      }
      @server.write "z0,/msg #{sender} new bot is now connected\r\n"
    end

    if data =~ /^Yplayer/ then
      nick = data[/^Y(.*)zB/,1]
      puts "[INFO] new bot: #{nick}"
      #@server.write "z0,/msg kemton new bot: #{nick}\r\n"
    end

    if data =~ /!update/ then
      sender = data[/\*(.*)\* !update/,1]
      response = JSON.parse( HTTParty.get( URI.parse(URI.encode("#{KIEKKO_API}user/=#{sender}?fields=id")) ) )
      sender_kiekko_id = response["id"]
      HTTParty.get( URI.parse(URI.encode("http://tilastot.tk/update/player/#{sender_kiekko_id}/referer}")) )
      @server.write "z0,/msg #{sender} Your stats has updated succesfully to tilastot.tk!\r\n"
    end

  end
  
end