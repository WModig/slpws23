def connect_to_db()
    db = SQLite3::Database.new("db/traningslogg.db") #path?
    db.results_as_hash = true
    return db
end

def exercise_from_workout(db)
    result = db.execute('SELECT * FROM workout_exercise_rel INNER JOIN exercises ON workout_exercise_rel.exercise_id = exercises.id')
    
