import json
import sqlite3
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--db_path", help="The path of db")
args = parser.parse_args()

DB_PATH = args.db_path

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

cursor.execute('''
    SELECT
        Id,
        Timestamp,
        Title,
        Description,
        LastModified
    FROM NoteDetail
    WHERE IsDeleted=0
'''
)

all_data_list = cursor.fetchall()

data_load = []
for row in all_data_list:
    decoded_content = row[3].encode('utf-8').decode('unicode_escape')
    temp_data = {
        'Id': row[0],
        'Timestamp': row[1],
        'Title': row[2],
        'Description': decoded_content,
        'LastModified': row[4]
    }
    data_load.append(temp_data)


note_data = {
    'data': data_load
}

print(json.dumps(note_data))
