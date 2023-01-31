def connect_to_db()
    db = SQLite3::Database.new("db/traningslogg.db")
    db.results_as_hash = true
    return db
end