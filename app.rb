require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$id_mutex = Mutex.new

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
    halt 400, { 'Content-Type' => 'application/json' }, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 422, { 'Content-Type' => 'application/json' }, json(error: 'text is required') unless text.is_a?(String)
  text = text.strip
  halt 422, { 'Content-Type' => 'application/json' }, json(error: 'text cannot be empty') if text.empty?
  halt 422, { 'Content-Type' => 'application/json' }, json(error: "text is too long (max #{MAX_TODO_LENGTH} characters)") if text.length > MAX_TODO_LENGTH

  todo = $id_mutex.synchronize do
    id = $next_id
    $next_id += 1
    t = { id: id, text: text, done: false, created_at: Time.now.to_s }
    $todos << t
    t
  end
  status 201
  json todo
end

patch '/api/todos/:id' do
  todo = $todos.find { |t| t[:id] == params[:id].to_i }
  halt 404, json(error: 'Not found') unless todo
  todo[:done] = !todo[:done]
  json todo
end

delete '/api/todos/:id' do
  original_size = $todos.size
  $todos.reject! { |t| t[:id] == params[:id].to_i }
  halt 404, json(error: 'Not found') if $todos.size == original_size
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
