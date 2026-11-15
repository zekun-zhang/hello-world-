require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$todos_mutex = Mutex.new

MAX_TEXT_LENGTH = 500

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
  data = JSON.parse(request.body.read) rescue nil
  halt 400, json(error: 'Invalid JSON') unless data.is_a?(Hash)

  text = data['text'].to_s.strip
  halt 400, json(error: 'text is required') if text.empty?
  halt 422, json(error: "text exceeds #{MAX_TEXT_LENGTH} characters") if text.length > MAX_TEXT_LENGTH

  todo = nil
  $todos_mutex.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
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
  $todos.reject! { |t| t[:id] == params[:id].to_i }
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
