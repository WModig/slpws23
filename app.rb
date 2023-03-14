require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:start)
end

get('/users/new') do
    slim(:"users/register")
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    if username == "" or password == ""
        slim(:"users/register")
    elsif password == password_confirm
        #Lägg till användare
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/traningslogg.db")
        db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)",username,password_digest)
        redirect('/')
    else
        #Felhantering
    end
end

get('/showlogin') do
    slim(:"users/login")
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/traningslogg.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect('/logs')
    else
        #Felhantering
    end
end

get('/logs') do
    id = session[:id].to_i
    db = connect_to_db()
    result = db.execute("SELECT * FROM logs WHERE user_id = ?", id)
    result2 = db.execute("SELECT username FROM users WHERE id = ?", id)
    slim(:"logs/index",locals:{logs:result, result2:result2})
end

get('/logs/new') do
    slim(:"logs/new")   
end

get('/logs/:id') do 
    id = params[:id].to_i
    db = connect_to_db()
    result = db.execute("SELECT * FROM logs WHERE id = ?",id).first
    result2 = exercises_from_workout(db,id)
    slim(:"logs/show",locals:{result:result, result2:result2})
end

post('/logs/new') do
    user_id = params[:user_id]
    content = params[:content]
    date = params[:date]
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("INSERT INTO logs (user_id, content, date) VALUES (?,?,?)",user_id,content,date)
    db.execute("INSERT INTO workout (user_id) VALUES (?)",user_id)
    redirect('/')
end


get('/logs/:id/edit') do
    id = params[:id].to_i
    db = connect_to_db()
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

post('/logs/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("DELETE FROM logs WHERE id = ?",id)
    redirect('/logs')
end