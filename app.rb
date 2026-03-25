require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

before do
  content_type :json if request.path_info.start_with?('/api/')
end

# In-memory todo store
$todos = []
$next_id = 1

helpers do
  def parse_json_body
    raw = request.body.read
    halt 400, json(error: 'Request body is required') if raw.nil? || raw.strip.empty?

    JSON.parse(raw)
  rescue JSON::ParserError
    halt 400, json(error: 'Malformed JSON')
  end
end

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
  data = parse_json_body
  text = data['text']&.strip
  halt 422, json(error: 'text is required') if text.nil? || text.empty?

  todo = { id: $next_id, text: text, done: false, created_at: Time.now.to_s }
  $next_id += 1
  $todos << todo

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
  removed_todo = $todos.find { |t| t[:id] == params[:id].to_i }
  halt 404, json(error: 'Not found') unless removed_todo

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
