require 'sqlite3'
require 'bcrypt'

def connect_to_db()
    db = SQLite3::Database.new("db/traningslogg.db") #path?
    db.results_as_hash = true
    return db
end

def exercises_from_workout(db, id)
    exercises = db.execute('SELECT exercises.name
                            FROM (workout_exercise_rel 
                                INNER JOIN exercises ON workout_exercise_rel.exercise_id = exercises.id)
                            WHERE workout_id = ?',id)
    return exercises
end