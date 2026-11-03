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
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  halt 400, json(error: 'Request body must be a JSON object') unless data.is_a?(Hash)

  text = data['text']
  halt 400, json(error: 'text is required') unless text.is_a?(String) && !text.strip.empty?
  halt 400, json(error: "text must be #{MAX_TODO_LENGTH} characters or fewer") if text.length > MAX_TODO_LENGTH

  todo = $mutex.synchronize do
    t = { id: $next_id, text: text.strip, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << t
    t
  end
  status 201
  json todo
end

patch '/api/todos/:id' do
  todo = $todos.find { |t| t[:id] == params[:id].to_i }
  halt 404, json(error: 'Not found') unless todo
  $mutex.synchronize { todo[:done] = !todo[:done] }
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
  halt 404, json(error: 'Not found') unless $todos.any? { |t| t[:id] == id }
  $mutex.synchronize { $todos.reject! { |t| t[:id] == id } }
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
