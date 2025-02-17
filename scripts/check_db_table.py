import sqlite3
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--db_path", help="The path of db")
args = parser.parse_args()

DB_PATH = args.db_path

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE IF NOT EXISTS "NoteDetail" (
        "Id"	INTEGER,
        "Timestamp"	TEXT,
        "Title"	TEXT,
        "Description"	TEXT,
        "Filepath"	TEXT,
        "Repo"	TEXT,
        "SearchPattern"	TEXT,
        "LastModified"	TEXT,
        "IsDeleted"	INTEGER,
        PRIMARY KEY("Id" AUTOINCREMENT)
    )
'''
)

print("Process Completed")
