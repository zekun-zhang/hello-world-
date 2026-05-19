require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

TODO_MAX_LENGTH = 500
MAX_TODOS = 1000

# In-memory todo store (Mutex guards concurrent access)
TODOS_LOCK = Mutex.new
$todos = []
$next_id = 1

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
  TODOS_LOCK.synchronize { json $todos.dup }
end

post '/api/todos' do
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 422, json(error: 'Text is required') unless text.is_a?(String)
  text = text.strip
  halt 422, json(error: 'Text is required') if text.empty?
  halt 422, json(error: "Text must be #{TODO_MAX_LENGTH} characters or fewer") if text.length > TODO_MAX_LENGTH

  todo = TODOS_LOCK.synchronize do
    halt 429, json(error: 'Todo limit reached') if $todos.size >= MAX_TODOS
    t = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << t
    t
  end
  status 201
  json todo
end

patch '/api/todos/:id' do
  todo = TODOS_LOCK.synchronize do
    t = $todos.find { |t| t[:id] == params[:id].to_i }
    t[:done] = !t[:done] if t
    t
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  removed = TODOS_LOCK.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == id }
    $todos.size < before
  end
  halt 404, json(error: 'Not found') unless removed
  json success: true
end

get '/api/stats' do
  TODOS_LOCK.synchronize do
    json(
      total: $todos.size,
      done: $todos.count { |t| t[:done] },
      pending: $todos.count { |t| !t[:done] },
      server_time: Time.now.to_s
    )
  end
end
