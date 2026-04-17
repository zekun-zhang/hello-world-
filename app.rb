require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$todos_mutex = Mutex.new

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
  $todos_mutex.synchronize { json $todos.dup }
end

post '/api/todos' do
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 400, json(error: 'text is required') unless text.is_a?(String)
  text = text.strip
  halt 400, json(error: 'text cannot be empty') if text.empty?
  halt 400, json(error: 'text is too long (max 500 characters)') if text.length > MAX_TODO_LENGTH

  todo = nil
  $todos_mutex.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  todo = nil
  $todos_mutex.synchronize do
    todo = $todos.find { |t| t[:id] == params[:id].to_i }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  found = false
  $todos_mutex.synchronize do
    original_size = $todos.size
    $todos.reject! { |t| t[:id] == id }
    found = $todos.size < original_size
  end
  halt 404, json(error: 'Not found') unless found
  json success: true
end

get '/api/stats' do
  $todos_mutex.synchronize do
    json(
      total: $todos.size,
      done: $todos.count { |t| t[:done] },
      pending: $todos.count { |t| !t[:done] }
    )
  end
end
