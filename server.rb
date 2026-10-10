require 'webrick'

server = WEBrick::HTTPServer.new(
  Port: 8080,
  DocumentRoot: File.join(File.dirname(__FILE__), 'public')
)

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start
