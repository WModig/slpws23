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
    error_message1 = nil
    slim(:"users/register", locals: {error_message1:error_message1})
end

post('/users/new') do
    error_message1 = nil
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    if username == "" or password == ""
        error_message1 = "Fälten kan inte vara tomma"
        slim(:"users/register", locals: {error_message1:error_message1})

    elsif password == password_confirm
        #Lägg till användare
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/traningslogg.db")
        db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)",username,password_digest)
        redirect('/showLogin')
    else
        error_message1 = "Passwords does not match!"
        slim(:'/users/register', locals: {error_message1:error_message1})
    end
end

get('/showlogin') do
    error_message = nil
    slim(:'/users/login', locals: {error_message: error_message})
end

post('/login') do
    error_message = nil
    username = params[:username]
    password = params[:password]
    db = connect_to_db()
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result == nil
        # Username not found
        error_message = "Incorrect username or password."
        slim(:"users/login", locals: {error_message: error_message})
    else
        pwdigest = result["pwdigest"]
        id = result["id"]

        if BCrypt::Password.new(pwdigest) == password
            # Successful login
            session[:id] = id
            redirect('/logs')
        else
            # Incorrect password
            error_message = "Incorrect username or password."
            slim(:"users/login", locals: {error_message: error_message})
        end
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
    error_message2 = nil
    if session[:id] == nil
        error_message2 = "Must be logged in"
    end
    slim(:"logs/new", locals:{error_message2:error_message2})   
end

post('/logs/new') do
    user_id = session[:id]
    content = params[:content]
    date = params[:date]
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("INSERT INTO logs (user_id, content, date) VALUES (?,?,?)",user_id,content,date)
    log_id = db.execute("SELECT last_insert_rowid();").first
    db.execute("INSERT INTO workout (user_id, log_id) VALUES (?,?)",user_id,log_id)
    redirect("/logs")
end

get('/logs/:id') do 
    id = params[:id].to_i
    db = connect_to_db()
    result = db.execute("SELECT * FROM logs WHERE id = ?", id).first
    result2 = db.execute("SELECT * FROM workout_exercise_rel WHERE workout_id = ?", id)
    slim(:"logs/show", locals: {result: result, result2: result2})
end


get('/logs/:log_id/exercises/new') do
    log_id = params[:log_id].to_i
    slim(:"exercises/new", locals: {log_id: log_id})
end

post('/logs/:log_id/exercises/create') do
    log_id = params[:log_id].to_i
    exercise_name = params[:exercise_name]
    reps = params[:reps].to_i
  
    db = connect_to_db()
    exercise = db.execute("SELECT id FROM exercises WHERE name = ?", exercise_name).first
    if exercise.nil?
      db.execute("INSERT INTO exercises (name) VALUES (?)", exercise_name)
      exercise_id = db.execute("SELECT last_insert_rowid();")
    else
      exercise_id = exercise['id']
    end
  
    db.execute("INSERT INTO workout_exercise_rel (workout_id, exercise_id, reps) VALUES (?, ?, ?)", log_id, exercise_id, reps)
  
    redirect("/logs/#{log_id}")
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
    db.execute("DELETE from workout WHERE log_id = ?",id)
    redirect('/logs')
end