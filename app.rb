require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

TODO_MAX_LENGTH = 500

# In-memory todo store — mutex guards all reads/writes
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
  json $todos_mutex.synchronize { $todos.dup }
end

post '/api/todos' do
  data = begin
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  text = data['text']
  halt 400, json(error: 'text must be a non-empty string') unless text.is_a?(String) && !text.strip.empty?
  halt 400, json(error: "text must be #{TODO_MAX_LENGTH} characters or fewer") if text.length > TODO_MAX_LENGTH

  todo = $todos_mutex.synchronize do
    t = { id: $next_id, text: text.strip, done: false, created_at: Time.now.to_s }
    $next_id += 1
    $todos << t
    t
  end
  json todo
end

patch '/api/todos/:id' do
  todo = $todos_mutex.synchronize do
    t = $todos.find { |x| x[:id] == params[:id].to_i }
    t[:done] = !t[:done] if t
    t
  end
  halt 404, json(error: 'Not found') unless todo
  json todo
end

delete '/api/todos/:id' do
  $todos_mutex.synchronize { $todos.reject! { |t| t[:id] == params[:id].to_i } }
  json success: true
end

get '/api/stats' do
  $todos_mutex.synchronize do
    json(
      total: $todos.size,
      done: $todos.count { |t| t[:done] },
      pending: $todos.count { |t| !t[:done] },
      server_time: Time.now.to_s,
      ruby_version: RUBY_VERSION
    )
  end
end
