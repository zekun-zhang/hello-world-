require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$todos_lock = Mutex.new

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
  todos_copy = $todos_lock.synchronize { $todos.dup }
  json todos_copy
end

post '/api/todos' do
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text'].to_s.strip
  halt 400, json(error: 'Text is required') if text.empty?
  halt 400, json(error: "Text must be #{MAX_TODO_LENGTH} characters or fewer") if text.length > MAX_TODO_LENGTH

  todo = nil
  $todos_lock.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  todo = nil
  $todos_lock.synchronize do
    todo = $todos.find { |t| t[:id] == params[:id].to_i }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  found = $todos_lock.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == id }
    $todos.size < before
  end
  halt 404, json(error: 'Not found') unless found
  json success: true
end

get '/api/stats' do
  total, done = $todos_lock.synchronize { [$todos.size, $todos.count { |t| t[:done] }] }
  json(
    total: total,
    done: done,
    pending: total - done,
    server_time: Time.now.to_s
  )
end
