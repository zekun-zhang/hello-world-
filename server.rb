require 'webrick'

server = WEBrick::HTTPServer.new(
  Port: 8080,
  DocumentRoot: File.dirname(__FILE__),
  NondisclosureName: ['.ht*', '.git', '.git*']
)

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start
