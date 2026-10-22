require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

MAX_TODO_LENGTH = 500
MAX_BODY_SIZE   = 10_000

# In-memory todo store — protected by a Mutex for thread safety
$todos  = []
$next_id = 1
$mutex  = Mutex.new

# Pages
get '/' do
  erb :home, layout: :layout
end

get '/about' do
  erb :about, layout: :layout
end

get '/contact' do
  erb :contact, layout: :layout
end

# API endpoints
get '/api/todos' do
  $mutex.synchronize { json $todos.dup }
end

post '/api/todos' do
  raw = request.body.read(MAX_BODY_SIZE)
  begin
    data = JSON.parse(raw)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 400, json(error: 'text must be a non-empty string') unless text.is_a?(String) && !text.strip.empty?
  halt 422, json(error: "text exceeds #{MAX_TODO_LENGTH} character limit") if text.length > MAX_TODO_LENGTH

  todo = nil
  $mutex.synchronize do
    todo = { id: $next_id, text: text.strip, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  status 201
  json todo
end

patch '/api/todos/:id' do
  todo = nil
  $mutex.synchronize do
    todo = $todos.find { |t| t[:id] == params[:id].to_i }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  $mutex.synchronize { $todos.reject! { |t| t[:id] == params[:id].to_i } }
  json success: true
end

get '/api/stats' do
  $mutex.synchronize do
    json(
      total: $todos.size,
      done: $todos.count { |t| t[:done] },
      pending: $todos.count { |t| !t[:done] },
      server_time: Time.now.to_s,
      ruby_version: RUBY_VERSION
    )
  end
end
