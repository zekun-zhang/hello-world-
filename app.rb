require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

# In-memory todo store
$todos = []
$next_id = 1
$todo_mutex = Mutex.new

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
  json $todo_mutex.synchronize { $todos.dup }
end

post '/api/todos' do
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  unless text.is_a?(String) && !text.strip.empty?
    halt 400, json(error: 'text is required and must be a non-empty string')
  end
  text = text.strip
  if text.length > 500
    halt 400, json(error: 'text must be 500 characters or fewer')
  end

  todo = $todo_mutex.synchronize do
    t = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << t
    t
  end
  json todo
end

patch '/api/todos/:id' do
  todo = $todo_mutex.synchronize do
    t = $todos.find { |t| t[:id] == params[:id].to_i }
    t[:done] = !t[:done] if t
    t
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  $todo_mutex.synchronize do
    $todos.reject! { |t| t[:id] == params[:id].to_i }
  end
  json success: true
end

get '/api/stats' do
  snapshot = $todo_mutex.synchronize { $todos.dup }
  json(
    total: snapshot.size,
    done: snapshot.count { |t| t[:done] },
    pending: snapshot.count { |t| !t[:done] },
    server_time: Time.now.to_s,
    ruby_version: RUBY_VERSION
  )
end
