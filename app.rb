require 'sinatra'
require 'sinatra/json'
require 'pg'
require 'json'

# ── Database connection ──────────────────────────
def db
  @db ||= PG.connect(
    host:     ENV['DB_HOST']     || 'database',
    port:     ENV['DB_PORT']     || 5432,
    dbname:   ENV['DB_NAME']     || 'myapp',
    user:     ENV['DB_USER']     || 'postgres',
    password: ENV['DB_PASSWORD'] || 'secret'
  )
end

# ── Create table on startup ──────────────────────
db.exec("CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
)")

# ── Routes ───────────────────────────────────────

# Health check endpoint
get '/health' do
  json status: 'ok', app: ENV['APP_NAME'] || 'REST API'
end

# List all items
get '/items' do
  result = db.exec("SELECT * FROM items ORDER BY created_at DESC")
  json result.map { |row| row }
end

# Get one item
get '/items/:id' do
  result = db.exec_params(
    "SELECT * FROM items WHERE id = $1", [params[:id]]
  )
  halt 404, json(error: 'Item not found') if result.ntuples == 0
  json result[0]
end

# Create a new item
post '/items' do
  body = JSON.parse(request.body.read)
  halt 400, json(error: 'Name is required') unless body['name']

  result = db.exec_params(
    "INSERT INTO items (name, description) VALUES ($1, $2) RETURNING *",
    [body['name'], body['description']]
  )
  status 201
  json result[0]
end

# Delete an item
delete '/items/:id' do
  result = db.exec_params(
    "DELETE FROM items WHERE id = $1 RETURNING *", [params[:id]]
  )
  halt 404, json(error: 'Item not found') if result.ntuples == 0
  json message: 'Deleted', item: result[0]
end