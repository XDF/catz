-- 
-- Catz - the world's most advanced cat show photo engine
-- Copyright (c) 2010-2011 Heikki Siltala
-- Licensed under The MIT License
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

PRAGMA FOREIGN_KEYS=1;

DROP TABLE IF EXISTS RUN;

CREATE TABLE RUN (
 DT INTEGER NOT NULL PRIMARY KEY CHECK (LENGTH(DT)=14) 
);

--

DROP TABLE IF EXISTS DNA;

CREATE TABLE DNA (
 CLASS TEXT NOT NULL,
 ITEM TEXT NOT NULL,
 DNA TEXT NOT NULL CHECK (LENGTH(DNA)=22),
 DT INTEGER NOT NULL CHECK (LENGTH(DT)=14),
 PRIMARY KEY (CLASS,ITEM)
);

--
                                                  
DROP TABLE IF EXISTS ALBUM;

CREATE TABLE ALBUM (
 ALBUMID INTEGER NOT NULL PRIMARY KEY,
 FOLDER TEXT NOT NULL UNIQUE,
 S INTEGER NULL UNIQUE CHECK (S IS NULL OR (S>0 AND S<1000))
);

-- 

DROP TABLE IF EXISTS PHOTO;

CREATE TABLE PHOTO (
 PHOTOID INTEGER NOT NULL PRIMARY KEY,
 ALBUMID INTEGER NOT NULL REFERENCES ALBUM(ALBUMID) ON DELETE CASCADE,
 N INTEGER NOT NULL CHECK (N>0 AND N<1000),
 X INTEGER NULL UNIQUE CHECK (X IS NULL OR (X>0 AND X<100000)),
 FILE TEXT NOT NULL CHECK (LENGTH(FILE)=8),
 HWIDTH INTEGER NOT NULL CHECK (HWIDTH>100 AND HWIDTH<2000),
 HHEIGHT INTEGER NOT NULL CHECK (HHEIGHT>100 AND HHEIGHT<2000),
 HBYTES INTEGER NOT NULL CHECK (HBYTES>0 AND HBYTES<5000000),
 LWIDTH INTEGER NOT NULL CHECK (LWIDTH>10 AND LWIDTH<500),
 LHEIGHT INTEGER NOT NULL CHECK (LHEIGHT>10 AND LWIDTH<500),
 LBYTES INTEGER NOT NULL CHECK (HBYTES>0 AND HBYTES<100000)
);

--

DROP TABLE IF EXISTS POSITION;

CREATE TABLE POSITION (
 POSITIONID INTEGER NOT NULL PRIMARY KEY,
 PHOTOID INTEGER NOT NULL REFERENCES PHOTO(PHOTOID) ON DELETE CASCADE,
 P INTEGER NOT NULL CHECK (P>0 AND P>10)
);

--

DROP TABLE IF EXISTS SUBJECT;

CREATE TABLE SUBJECT (
 SUBJECTID INTEGER NOT NULL PRIMARY KEY,
 SUBJECT TEXT NOT NULL UNIQUE,
 SORT_SUBJECT INTEGER NOT NULL UNIQUE CHECK (SORT_SUBJECT>0)
);

INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('album',101);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('name',102);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('date',103);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('loc',104);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('org',105);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('umb',106);

INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('lens',301);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('body',302);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('flen',303);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('fnum',304);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('etime',305);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('iso',306);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('dt',307);

INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('text',401);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('cat',402);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('breed',403);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('breeder',404);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('code',405);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('color',406);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('feature',407);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('nick',408);
INSERT INTO SUBJECT(SUBJECT,SORT_SUBJECT) VALUES ('title',409);

--

DROP TABLE IF EXISTS OBJECT;

CREATE TABLE OBJECT (
 OBJECTID INTEGER NOT NULL PRIMARY KEY,
 SUBJECTID INTEGER NOT NULL REFERENCES SUBJECT(SUBJECTID),
 OBJECT_EN TEXT NOT NULL,
 SORT_EN TEXT NULL,
 OBJECT_FI TEXT NULL,
 SORT_FI TEXT NULL
);

CREATE UNIQUE INDEX OBJECT_IX1 ON OBJECT(SUBJECTID,OBJECT_EN);

--

DROP TABLE IF EXISTS INALBUM;

CREATE TABLE INALBUM (
 ALBUMID INTEGER NOT NULL REFERENCES ALBUM(ALBUMID) ON DELETE CASCADE,
 OBJECTID INTEGER NOT NULL REFERENCES OBJECT(OBJECTID),
 PRIMARY KEY (ALBUMID,OBJECTID)
);

--

DROP TABLE IF EXISTS INPHOTO;

CREATE TABLE INPHOTO (
 PHOTOID INTEGER NOT NULL REFERENCES PHOTO(PHOTOID) ON DELETE CASCADE,
 OBJECTID INTEGER NOT NULL REFERENCES OBJECT(OBJECTID),
 PRIMARY KEY (PHOTOID,OBJECTID)
);

--

DROP TABLE IF EXISTS INEXIF;

CREATE TABLE INEXIF (
 PHOTOID INTEGER NOT NULL REFERENCES PHOTO(PHOTOID) ON DELETE CASCADE,
 OBJECTID_META INTEGER NULL REFERENCES OBJECT(OBJECTID),
 OBJECTID_DATA INTEGER NULL REFERENCES OBJECT(OBJECTID),
 OBJECTID_FILE INTEGER NULL REFERENCES OBJECT(OBJECTID),
 CHECK (
  OBJECTID_META IS NOT NULL OR 
  OBJECTID_DATA IS NOT NULL OR
  OBJECTID_FILE IS NOT NULL
 )
);

--

DROP TABLE IF EXISTS INPOSITION;

CREATE TABLE INPOSITION (
 POSITIONID INTEGER NOT NULL REFERENCES POSITION(POSITIONID) ON DELETE CASCADE,
 OBJECTID INTEGER NOT NULL REFERENCES OBJECT(OBJECTID),
 PRIMARY KEY (POSITIONID,OBJECTID)
);

--

DROP TABLE IF EXISTS METABREEDER;

CREATE TABLE METABREEDER (
 BREEDER TEXT PRIMARY KEY NOT NULL,
 SITEURL TEXT NULL,
 COUNTRY TEXT NULL
);

--
                                
DROP TABLE IF EXISTS METABREED;

CREATE TABLE METABREED (
 EMS TEXT PRIMARY KEY NOT NULL CHECK(LENGTH(EMS)=3),
 BREED_EN TEXT NOT NULL,
 BREED_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS METACOUNTRY;

CREATE TABLE METACOUNTRY (
 CODE PRIMARY KEY NOT NULL CHECK(LENGTH(CODE)=2),
 COUNTRY_EN TEXT NOT NULL,
 COUNTRY_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS METANEWS;

CREATE TABLE METANEWS (
 DT INTEGER PRIMARY KEY NOT NULL CHECK(LENGTH(DT)=14),
 TITLE_EN TEXT NOT NULL,
 TEXT_EN TEXT NOT NULL,
 TITLE_FI TEXT NOT NULL,
 TEXT_FI TEXT NOT NULL
);

--
