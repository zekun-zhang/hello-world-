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

  text = data['text'].to_s.strip
  halt 400, json(error: 'Text is required') if text.empty?
  halt 400, json(error: "Text must be #{MAX_TODO_LENGTH} characters or fewer") if text.length > MAX_TODO_LENGTH

  todo = nil
  $mutex.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  todo = $todos.find { |t| t[:id] == params[:id].to_i }
  halt 404, json(error: 'Not found') unless todo
  $mutex.synchronize { todo[:done] = !todo[:done] }
  json todo
end

delete '/api/todos/:id' do
  found = false
  $mutex.synchronize do
    before = $todos.size
    $todos.reject! { |t| t[:id] == params[:id].to_i }
    found = $todos.size < before
  end
  halt 404, json(error: 'Not found') unless found
  json success: true
end

get '/api/stats' do
  json(
    total: $todos.size,
    done: $todos.count { |t| t[:done] },
    pending: $todos.count { |t| !t[:done] },
    server_time: Time.now.to_s
  )
end
