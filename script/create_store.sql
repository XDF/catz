--
-- The MIT License
-- 
-- Copyright (c) 2010-2011 Heikki Siltala
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
-- 

DROP TABLE IF EXISTS RUN;

CREATE TABLE RUN (
 DT INTEGER NOT NULL PRIMARY KEY 
);

--

DROP TABLE IF EXISTS DNA;

CREATE TABLE DNA (
 CLASS TEXT NOT NULL,
 ITEM TEXT NOT NULL,
 DNA TEXT NOT NULL,
 DT INTEGER NOT NULL,
 PRIMARY KEY (CLASS,ITEM)
);

--
                                                  
DROP TABLE IF EXISTS SECTION;

CREATE TABLE SECTION (
 S INTEGER PRIMARY KEY NOT NULL,
 SECTION_EN TEXT NOT NULL,
 SECTION_FI TEXT NOT NULL,
 ALBUM TEXT NOT NULL
);

--

DROP TABLE IF EXISTS ALBUM;

CREATE TABLE ALBUM (
 ALBUM TEXT PRIMARY KEY NOT NULL,
 NAME_EN TEXT NOT NULL,
 NAME_FI TEXT NOT NULL,
 DESC_EN TEXT NOT NULL,
 DESC_FI TEXT NOT NULL,
 LIBERTY TEXT NOT NULL,
 YEARS TEXT NOT NULL,
 LENSMODE TEXT NOT NULL,
 CREATED INTEGER NOT NULL,                                                                                                                                            
 MODIFIED INTEGER NOT NULL,
 ORIGINED INTEGER NULL,
 LOCATION_EN TEXT NULL,
 LOCATION_FI TEXT NULL,
 COUNTRY TEXT NULL,
 ORGANIZER_EN TEXT NULL,
 ORGANIZER_FI TEXT NULL,
 UMBRELLA_EN TEXT NULL,
 UMBRELLA_FI TEXT NULL
);

--

DROP TABLE IF EXISTS FLESH;

CREATE TABLE FLESH (
 FID INTEGER PRIMARY KEY NOT NULL,
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL
);

CREATE UNIQUE INDEX FLESH_IX1 ON FLESH(ALBUM,N);

--

DROP TABLE IF EXISTS FLESH_LINE;

CREATE TABLE FLESH_LINE (
 FID INTEGER PRIMARY KEY NOT NULL,
 LID INTEGER NOT NULL
);

--

DROP TABLE IF EXISTS EXID;

CREATE TABLE EXID (
 FID INTEGER PRIMARY KEY NOT NULL,
 FLEN REAL NULL,
 ETIME_TXT TEXT NULL,
 ETIME_NUM REAL NULL,
 FNUM REAL NULL,
 DT INTEGER NULL,
 ISO INTEGER NULL,
 BODY TEXT NULL,
 LENS TEXT NULL
);

--

DROP TABLE IF EXISTS LINE;

CREATE TABLE LINE (
 LID INTEGER PRIMARY KEY NOT NULL,
 LINE TEXT NOT NULL
);

CREATE UNIQUE INDEX LINE_IX1 ON LINE(LINE);

--

DROP TABLE IF EXISTS LINE_SNIP;

CREATE TABLE LINE_SNIP (
 LID INTEGER NOT NULL,
 SID INTEGER NOT NULL,
 P INTEGER NOT NULL,
 PRIMARY KEY (LID,P)
);

CREATE INDEX LINE_SNIP_IX1 ON LINE_SNIP(LID);

CREATE INDEX LINE_SNIP_IX2 ON LINE_SNIP(SID);

--

DROP TABLE IF EXISTS SNIP;

CREATE TABLE SNIP (
 SID INTEGER PRIMARY KEY NOT NULL,
 SNIP TEXT NOT NULL,
 OUT_EN TEXT NOT NULL,
 OUT_FI TEXT NOT NULL

);

CREATE UNIQUE INDEX SNIP_IX1 ON SNIP(SNIP);

--

DROP TABLE IF EXISTS SNIP_PART;

CREATE TABLE SNIP_PART (
 SID INTEGER NOT NULL,
 PID INTEGER NOT NULL,
 PRIMARY KEY (SID,PID)
);

CREATE INDEX SNIP_PART_IX1 ON SNIP_PART(SID);

CREATE INDEX SNIP_PART_IX2 ON SNIP_PART(PID);

--

DROP TABLE IF EXISTS PART;

CREATE TABLE PART (
 PID INTEGER PRIMARY KEY NOT NULL,
 AREA TEXT NOT NULL,
 PART TEXT NOT NULL
);

CREATE UNIQUE INDEX PART_AREA_IX1 ON PART(AREA,PART);

--

DROP TABLE IF EXISTS METARESULT;

CREATE TABLE METARESULT (
 RESULT TEXT PRIMARY KEY NOT NULL
);

--

DROP TABLE IF EXISTS METABREEDER;

CREATE TABLE METABREEDER (
 BREEDER TEXT PRIMARY KEY NOT NULL,
 SITEURL TEXT NOT NULL,
 PHOTOURL TEXT NOT NULL,
 COUNTRY TEXT NOT NULL
);

--
                                
DROP TABLE IF EXISTS METABREED;

CREATE TABLE METABREED (
 PART TEXT PRIMARY KEY NOT NULL,
 BREED_EN TEXT NOT NULL,
 BREED_FI TEXT NOT NULL,
 PHOTOURL TEXT NOT NULL
);

--

DROP TABLE IF EXISTS METACOUNTRY;

CREATE TABLE METACOUNTRY (
 COUNTRY TEXT PRIMARY KEY NOT NULL,
 COUNTRY_EN TEXT NOT NULL,
 COUNTRY_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS METANEWS;

CREATE TABLE METANEWS (
 DT INTEGER PRIMARY KEY NOT NULL,
 TITLE_EN TEXT NOT NULL,
 TEXT_EN TEXT NOT NULL,
 TITLE_FI TEXT NOT NULL,
 TEXT_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS METATEXT;

CREATE TABLE METATEXT (
 TAG TEXT PRIMARY KEY NOT NULL,
 TEXT_EN TEXT NOT NULL,
 TEXT_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS PHOTO;

CREATE TABLE PHOTO (
 FID INTEGER PRIMARY KEY NOT NULL,
 FILE VARCHAR(8) NOT NULL,
 WIDTH_HR INTEGER NOT NULL,
 HEIGHT_HR INTEGER NOT NULL,
 BYTES_HR INTEGER NOT NULL,
 WIDTH_LR INTEGER NOT NULL,
 HEIGHT_LR INTEGER NOT NULL,
 BYTES_LR INTEGER NOT NULL
);


--

DROP TABLE IF EXISTS EXIF;

CREATE TABLE EXIF (
 FID INTEGER PRIMARY KEY NOT NULL,
 FLEN REAL,
 ETIME_TXT TEXT,
 ETIME_NUM REAL,
 FNUM REAL,
 DT INTEGER,
 ISO INTEGER,
 BODY TEXT,
 LENS TEXT
);
