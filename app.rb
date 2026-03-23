require 'sinatra'
require 'sinatra/json'
require 'json'
require 'sequel'

set :port, 8080
set :bind, '0.0.0.0'

# Database setup
DB = Sequel.connect('sqlite://todos.db')

DB.create_table? :todos do
  primary_key :id
  String :text, null: false
  TrueClass :done, default: false
  DateTime :created_at
end

todos = DB[:todos]

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
  json todos.all
end

post '/api/todos' do
  data = JSON.parse(request.body.read)
  id = todos.insert(text: data['text'], done: false, created_at: Time.now)
  json todos.where(id: id).first
end

patch '/api/todos/:id' do
  todo = todos.where(id: params[:id].to_i).first
  halt 404, json(error: 'Not found') unless todo
  todos.where(id: params[:id].to_i).update(done: !todo[:done])
  json todos.where(id: params[:id].to_i).first
end

delete '/api/todos/:id' do
  todos.where(id: params[:id].to_i).delete
  json success: true
end

get '/api/stats' do
  json(
    total: todos.count,
    done: todos.where(done: true).count,
    pending: todos.where(done: false).count,
    server_time: Time.now.to_s,
    ruby_version: RUBY_VERSION
  )
end
