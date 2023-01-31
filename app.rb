require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:start)
end

get('/logs') do
    db = SQLite3::Database.new("db/traningslogg.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM logs")
    p result
    slim(:"logs/index",locals:{logs:result})
end
  
get('/logs/new') do
    slim(:"logs/new")
end

post('/logs/new') do
    user_id = params[:user_id]
    content = params[:content]
    date = params[:date]
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("INSERT INTO logs (user_id, content, date) VALUES (?,?,?)",user_id,content,date)
    slim(:"logs/new")
end


get('/logs/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/traningslogg.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM logs WHERE id = ?",id).first
    slim(:"logs/edit",locals:{result:result})
end

post('/logs/:id/update') do
    content = params[:content]
    date = params[:date]
    id = params[:id].to_i
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("UPDATE logs SET content = ?,date = ? WHERE id = ?",content,date,id)
    redirect('/logs')
  end