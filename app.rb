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
        redirect('/showLogin')
    else
        #Felhantering
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
    db = SQLite3::Database.new("db/traningslogg.db")
    db.results_as_hash = true
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
    slim(:"logs/new")   
end

post('/logs/new') do
    user_id = params[:user_id]
    content = params[:content]
    date = params[:date]
    db = SQLite3::Database.new("db/traningslogg.db")
    db.execute("INSERT INTO logs (user_id, content, date) VALUES (?,?,?)",user_id,content,date)
    log_id = db.execute("SELECT last_insert_rowid();")
    db.execute("INSERT INTO workout (user_id, log_id) VALUES (?,?)",user_id,log_id)
    redirect("/logs/#{log_id}/exercises/new")
end

get('/logs/:id') do 
    id = params[:id].to_i
    db = connect_to_db()
    result = db.execute("SELECT * FROM logs WHERE id = ?", id).first
    result2 = db.execute("SELECT * FROM workout_exercise_rel WHERE workout_id = ?", id)
    puts result2.inspect
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
  
    # Add exercise to the exercises table if it doesn't exist
    db = connect_to_db()
    exercise = db.execute("SELECT id FROM exercises WHERE name = ?", exercise_name).first
    if exercise.nil?
      db.execute("INSERT INTO exercises (name) VALUES (?)", exercise_name)
      exercise_id = db.last_insert_row_id
    else
      exercise_id = exercise['id']
    end
  
    # Add the exercise and reps to the workout_exercise_rel table
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
    redirect('/logs')
end