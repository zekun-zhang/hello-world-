require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# Thread-safe in-memory todo store
TODOS_MUTEX = Mutex.new
$todos = []
$next_id = 1

MAX_TODO_LENGTH = 500
MAX_TODOS = 1000

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
  TODOS_MUTEX.synchronize { json $todos.dup }
end

post '/api/todos' do
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  unless text.is_a?(String) && !text.strip.empty?
    halt 400, json(error: 'text must be a non-empty string')
  end
  if text.length > MAX_TODO_LENGTH
    halt 400, json(error: "text must be #{MAX_TODO_LENGTH} characters or fewer")
  end

  todo = nil
  TODOS_MUTEX.synchronize do
    halt 429, json(error: 'Todo limit reached') if $todos.size >= MAX_TODOS
    todo = { id: $next_id, text: text.strip, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  todo = nil
  TODOS_MUTEX.synchronize do
    todo = $todos.find { |t| t[:id] == params[:id].to_i }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  deleted = false
  TODOS_MUTEX.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == params[:id].to_i }
    deleted = $todos.size < before
  end
  halt 404, json(error: 'Not found') unless deleted
  json success: true
end

get '/api/stats' do
  TODOS_MUTEX.synchronize do
    json(
      total: $todos.size,
      done: $todos.count { |t| t[:done] },
      pending: $todos.count { |t| !t[:done] },
      server_time: Time.now.to_s
    )
  end
end
