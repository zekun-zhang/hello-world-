require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$todos_mutex = Mutex.new

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
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 400, json(error: 'text must be a string') unless text.is_a?(String)
  text = text.strip
  halt 400, json(error: 'text cannot be empty') if text.empty?
  halt 400, json(error: 'text must be 500 characters or fewer') if text.length > 500

  todo = nil
  $todos_mutex.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  id = params[:id].to_i
  todo = nil
  $todos_mutex.synchronize do
    todo = $todos.find { |t| t[:id] == id }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  deleted = false
  $todos_mutex.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == id }
    deleted = $todos.size < before
  end
  halt 404, json(error: 'Not found') unless deleted
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
