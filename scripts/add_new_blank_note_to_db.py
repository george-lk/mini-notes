import sqlite3
import time
import argparse
from datetime import datetime

parser = argparse.ArgumentParser()
parser.add_argument("--db_path", help="The path of db")
args = parser.parse_args()

DB_PATH = args.db_path

file_content = ''
file_content_encoded = file_content.encode('unicode_escape').decode('utf-8')

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

title = 'Blank Note'
timestamp_epoch = int(datetime.now().timestamp())
lastModified = int(datetime.now().timestamp())
isDeleted = 0

cursor.execute('INSERT INTO NoteDetail (Timestamp,Title,Description,LastModified, IsDeleted) VALUES (?, ?, ?, ?, ?)', (timestamp_epoch, title, file_content_encoded, lastModified, isDeleted,))

conn.commit()
conn.close()

print("File content has been stored in the database.")

