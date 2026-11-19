require 'webrick'

public_dir = File.join(File.dirname(__FILE__), 'public')
Dir.mkdir(public_dir) unless Dir.exist?(public_dir)

server = WEBrick::HTTPServer.new(
  Port: 8080,
  DocumentRoot: public_dir
)

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start
