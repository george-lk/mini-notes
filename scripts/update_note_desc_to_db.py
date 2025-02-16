import sqlite3
import time
import argparse
from datetime import datetime

parser = argparse.ArgumentParser()
parser.add_argument("--note_id", help="ID of the note")
parser.add_argument("--input_desc_file", help="Description Input File")
parser.add_argument("--input_title_file", help="Title Input File")
parser.add_argument("--db_path", help="The path of db")
args = parser.parse_args()

note_id = args.note_id
desc_input_file = args.input_desc_file
title_input_file = args.input_title_file
DB_PATH = args.db_path

with open(title_input_file, 'r') as title_file:
    title_content = title_file.readline().strip('\n')

title_content_encoded = title_content.encode('unicode_escape').decode('utf-8')

with open(desc_input_file, 'r') as desc_file:
    file_content = desc_file.read()

file_content_encoded = file_content.encode('unicode_escape').decode('utf-8')

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

cursor.execute('UPDATE NoteDetail SET Description= ?, Title=? WHERE id=?', (file_content_encoded, title_content_encoded,note_id,))

conn.commit()
conn.close()

print("File content has been updated")
