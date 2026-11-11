require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$mutex = Mutex.new

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
  halt 400, json(error: 'Text too long (max 500 characters)') if text.length > 500
  todo = nil
  $mutex.synchronize do
    todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << todo
  end
  json todo
end

patch '/api/todos/:id' do
  id = params[:id].to_i
  todo = nil
  $mutex.synchronize do
    todo = $todos.find { |t| t[:id] == id }
    todo[:done] = !todo[:done] if todo
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  id = params[:id].to_i
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
