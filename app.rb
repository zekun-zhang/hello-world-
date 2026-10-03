require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$mutex = Mutex.new

MAX_TODO_LENGTH = 500

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
  json $todos
end

post '/api/todos' do
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 400, json(error: 'text must be a string') unless text.is_a?(String)
  text = text.strip
  halt 400, json(error: 'text cannot be blank') if text.empty?
  halt 400, json(error: "text too long (max #{MAX_TODO_LENGTH} chars)") if text.length > MAX_TODO_LENGTH

  todo = $mutex.synchronize do
    t = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << t
    t
  end
  status 201
  json todo
end

patch '/api/todos/:id' do
  id = params[:id].to_i
  todo = $mutex.synchronize { $todos.find { |t| t[:id] == id } }
  halt 404, json(error: 'Not found') unless todo
  $mutex.synchronize { todo[:done] = !todo[:done] }
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  removed = $mutex.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == id }
    $todos.size < before
  end
  halt 404, json(error: 'Not found') unless removed
  json success: true
end

get '/api/stats' do
  json(
    total: $todos.size,
    done: $todos.count { |t| t[:done] },
    pending: $todos.count { |t| !t[:done] },
    server_time: Time.now.to_s,
    ruby_version: RUBY_VERSION
  )
end
