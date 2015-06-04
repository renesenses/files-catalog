	CREATE TABLE file (
			file_md5 TEXT PRIMARY KEY NOT NULL,
			file_size INTEGER,
			file_type TEXT,
			file_nbocc INTEGER NOT NULL,
			file_time TEXT
    	);

    CREATE TABLE location (
    		loc_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    		file_md5 TEXT NOT NULL REFERENCES file(file_md5), 
    		loc_full TEXT NOT NULL,
    		loc_name TEXT NOT NULL,
    		loc_vol TEXT,
    		loc_path TEXT,
    		loc_ext TEXT
    	);
