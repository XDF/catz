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
                                                  
DROP TABLE IF EXISTS ALBUM;

CREATE TABLE ALBUM (
 AID INTEGER NOT NULL PRIMARY KEY,
 FOLDER TEXT NOT NULL,
 S INTEGER NULL
);

CREATE UNIQUE INDEX ALBUM1 ON ALBUM(FOLDER);
CREATE UNIQUE INDEX ALBUM2 ON ALBUM(S);

--

DROP TABLE IF EXISTS PHOTO;

CREATE TABLE PHOTO (
 AID INTEGER NOT NULL,
 N INTEGER NOT NULL,
 X INTEGER NULL,
 FILE TEXT NOT NULL,
 MOMENT TEXT NULL,
 HWIDTH INTEGER NOT NULL,
 HHEIGHT INTEGER NOT NULL,
 LWIDTH INTEGER NOT NULL,
 LHEIGHT INTEGER NOT NULL,
 PRIMARY KEY (AID, N)
);

CREATE UNIQUE INDEX PHOTO1 ON PHOTO(X);

--

DROP TABLE IF EXISTS INALBUM;

CREATE TABLE INALBUM (
 AID INTEGER NOT NULL,
 SID INTEGER NOT NULL
);

CREATE INDEX INALBUM1 ON INALBUM(AID);
CREATE INDEX INALBUM2 ON INALBUM(SID);

--

DROP TABLE IF EXISTS INEXIF;

CREATE TABLE INEXIF (
 AID INTEGER NOT NULL,
 N INTEGER NOT NULL,
 PID TEXT NOT NULL,
 SID_META INTEGER NULL,
 SID_DATA INTEGER NULL,
 SID_FILE INTEGER NULL 
);

CREATE UNIQUE INDEX INEXIF1 ON INEXIF(AID,N,PID);
CREATE INDEX INEXIF2 ON INEXIF(SID_META);
CREATE INDEX INEXIF3 ON INEXIF(SID_DATA);
CREATE INDEX INEXIF4 ON INEXIF(SID_FILE);

DROP VIEW IF EXISTS INEXIFF;

CREATE VIEW INEXIFF AS
 SELECT 
  AID,N,PID,
  COALESCE(SID_DATA,SID_META,SID_FILE) AS SID
 FROM
  INEXIF;

--

DROP TABLE IF EXISTS INPOS;

CREATE TABLE INPOS (
 AID INTEGER NOT NULL,
 N INTEGER NOT NULL,
 P INTEGER NOT NULL,
 SID INTEGER NOT NULL
);

CREATE INDEX INPOS1 ON INPOS(AID,N,P);
CREATE INDEX INPOS2 ON INPOS(SID);

--

DROP TABLE IF EXISTS SEC;

CREATE TABLE SEC (
 SID INTEGER PRIMARY KEY NOT NULL,
 PID INTEGER NOT NULL,
 SEC_EN TEXT NOT NULL,
 SORT_EN TEXT NULL,
 SEC_FI TEXT NULL,
 SORT_FI TEXT NULL
);
 
CREATE INDEX SEC1 ON SEC(SEC_EN);
CREATE INDEX SEC2 ON SEC(SEC_FI);

--

DROP VIEW IF EXISTS SEC_EN;

CREATE VIEW SEC_EN AS
 SELECT 
  SID,PID,
  SEC_EN AS SEC,
  COALESCE(SORT_EN,SEC_EN) AS SORT
 FROM 
  SEC; 

DROP VIEW IF EXISTS SEC_FI;

CREATE VIEW SEC_FI AS
 SELECT 
  SID,PID,
  COALESCE(SEC_FI,SEC_EN) AS SEC, 
  COALESCE(SORT_FI,SORT_EN,SEC_FI,SEC_EN) AS SORT
 FROM 
  SEC; 

--

DROP TABLE IF EXISTS PRI;

CREATE TABLE PRI (
 PID INTEGER NOT NULL PRIMARY KEY,
 PRI TEXT NOT NULL,
 ORIGIN TEXT NOT NULL,
 DISP INTEGER NOT NULL
);

CREATE UNIQUE INDEX PRI1 ON PRI(PRI);

INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('album','album',11);                   
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('folder','album',12);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('date','album',13);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('loc','album',14);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('org','album',15);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('umb','album',16);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('text','pos',21);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('cat','pos',31);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('breeder','pos',32);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('nat','pos',33);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('code','pos',34);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('breed','pos',35);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('cate','pos',36);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('app','pos',37);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('feat','pos',38);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('nick','pos',39);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('title','pos',40);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('lens','exif',51);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('body','exif',52);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('fnum','exif',53);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('etime','exif',54);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('iso','exif',55);
INSERT INTO PRI (PRI,ORIGIN,DISP) VALUES ('flen','exif',56);
 
--

DROP TABLE IF EXISTS MBREEDER;

CREATE TABLE MBREEDER (
 BREEDER TEXT PRIMARY KEY NOT NULL,
 NAT TEXT NOT NULL
);

--
                                
DROP TABLE IF EXISTS MBREED;

CREATE TABLE MBREED (
 BREED TEXT PRIMARY KEY NOT NULL,
 CATE INTEGER NOT NULL,
 BREED_EN TEXT NOT NULL,
 BREED_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MCATE;

CREATE TABLE MCATE (
 CATE INTEGER PRIMARY KEY NOT NULL,
 CATE_EN TEXT NOT NULL,
 CATE_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MFEAT;

CREATE TABLE MFEAT (
 FEAT TEXT PRIMARY KEY NOT NULL,
 FEAT_EN TEXT NOT NULL,
 FEAT_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MNAT;

CREATE TABLE MNAT (
 NAT TEXT PRIMARY KEY NOT NULL,
 NAT_EN TEXT NOT NULL,
 NAT_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MNEWS;

CREATE TABLE MNEWS (
 DT INTEGER PRIMARY KEY NOT NULL,
 TITLE_EN TEXT NOT NULL,
 TITLE_FI TEXT NOT NULL,
 TEXT_EN TEXT NOT NULL,
 TEXT_FI TEXT NOT NULL,
 URL_EN TEXT NULL,
 URL_FI TEXT NULL
);

--

DROP TABLE IF EXISTS MTITLE;

CREATE TABLE MTITLE (
 TITLE TEXT PRIMARY KEY NOT NULL,
 TITLE_EN TEXT NOT NULL,
 TITLE_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MSKIP;

CREATE TABLE MSKIP (
 MESS TEXT PRIMARY KEY NOT NULL
);

--

DROP TABLE IF EXISTS CRUN;

CREATE TABLE CRUN (
 DT INTEGER NOT NULL PRIMARY KEY
);

--

DROP TABLE IF EXISTS CCLASS;

CREATE TABLE CCLASS (
 CLASS TEXT PRIMARY KEY NOT NULL,
 PHASE INTEGER NOT NULL,
 CNTITEM INTEGER NOT NULL,
 CNTSKIP INTEGER NOT NULL
);

--

DROP TABLE IF EXISTS CITEM;

CREATE TABLE CITEM (
 CLASS TEXT NOT NULL,
 ITEM INTEGER NOT NULL,
 MESS TEXT NOT NULL,
 PRI TEXT NULL,
 SEC TEXT NULL,
 SEC2 TEXT NULL,
 PRIMARY KEY (CLASS,ITEM)
);

-- 