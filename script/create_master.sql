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
                                                  
DROP TABLE IF EXISTS ALBUM;

CREATE TABLE ALBUM (
 ALBUM TEXT NOT NULL PRIMARY KEY,
 NAME_EN TEXT NOT NULL,
 NAME_FI TEXT NOT NULL,
 ORIGINED INTEGER NOT NULL,
 CREATED INTEGER NOT NULL,                                                                                                                                           
 MODIFIED INTEGER NOT NULL,
 LOC_EN TEXT NOT NULL,
 LOC_FI TEXT NOT NULL,
 NAT TEXT NOT NULL
);

--

DROP TABLE IF EXISTS ORG;

CREATE TABLE ORG (
 ALBUM TEXT NOT NULL,
 ORG_EN TEXT NOT NULL,
 ORG_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS UMB;

CREATE TABLE UMB (
 ALBUM TEXT NOT NULL,
 UMB_EN TEXT NOT NULL,
 UMB_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS PHOTO;

CREATE TABLE PHOTO (
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL,
 FILE TEXT NOT NULL,
 WIDTH_HR INTEGER NOT NULL,
 HEIGHT_HR INTEGER NOT NULL,
 BYTES_HR INTEGER NOT NULL,
 WIDTH_LR INTEGER NOT NULL,
 HEIGHT_LR INTEGER NOT NULL,
 BYTES_LR INTEGER NOT NULL,
 PRIMARY KEY (ALBUM, N)
);

--


DROP TABLE IF EXISTS DEXIF;

CREATE TABLE DEXIF (
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL,
 KEY TEXT NOT NULL,
 VAL TEXT NOT NULL
);

CREATE INDEX DEXIF_IX1 ON DEXIF(ALBUM,N);

--

DROP TABLE IF EXISTS FEXIF;

CREATE TABLE FEXIF (
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL,
 KEY TEXT NOT NULL,
 VAL TEXT NOT NULL
);

CREATE INDEX FEXIF_IX1 ON FEXIF(ALBUM,N);

--

DROP TABLE IF EXISTS MEXIF;

CREATE TABLE MEXIF (
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL,
 KEY TEXT NOT NULL,
 VAL TEXT NOT NULL
);

CREATE INDEX MEXIF_IX1 ON MEXIF(ALBUM,N);

--

DROP TABLE IF EXISTS SNIP;

CREATE TABLE SNIP (
 ALBUM TEXT NOT NULL,
 N INTEGER NOT NULL,
 P INTEGER NOT NULL,
 SID INTEGER NOT NULL
);

CREATE INDEX SNIP_IX1 ON SNIP(ALBUM,N);

--

DROP TABLE IF EXISTS SEC;

CREATE TABLE SEC (
 SID INTEGER PRIMARY KEY NOT NULL,
 PID INTEGER NOT NULL,
 SEC_EN TEXT NOT NULL,
 SORT_EN TEXT NOT NULL,
 SEC_FI TEXT NOT NULL,
 SORT_FI TEXT NOT NULL
);
 
CREATE INDEX SEC_IX1 ON SEC(PID);
CREATE UNIQUE INDEX SEC_IX2 ON SEC(PID,SEC_EN);
CREATE INDEX SEC_IX3 ON SEC(SEC_EN);
CREATE INDEX SEC_IX4 ON SEC(SEC_FI);

--

DROP TABLE IF EXISTS PRI;

CREATE TABLE PRI (
 PID INTEGER PRIMARY KEY NOT NULL,
 PRI TEXT NOT NULL,
 SORT_PRI INTEGER NOT NULL
);

-- > < 99 general 
                   
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('date',1);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('loc',2);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('org',3);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('umb',4);

-- > 99 and < 999: cat 

INSERT INTO PRI (PRI,SORT_PRI) VALUES ('cat',111);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('breed',112);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('breeder',113);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('ems5',114);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('ems3',115);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('ems4',116);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('ems1',117);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('nat',118);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('nick',119);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('title',120);

-- > 999 and < 9999: camera

INSERT INTO PRI (PRI,SORT_PRI) VALUES ('lens',1001);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('body',1002);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('fnum',1003);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('etime',1004);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('iso',1005);
INSERT INTO PRI (PRI,SORT_PRI) VALUES ('flen',1006);

-- > 9999 - : items not listed

INSERT INTO PRI (PRI,SORT_PRI) VALUES ('dt',10001);

INSERT INTO PRI (PRI,SORT_PRI) VALUES ('out',20001);

CREATE INDEX PRI_IX1 ON PRI(PRI);
 
--

DROP TABLE IF EXISTS MBREEDER;

CREATE TABLE MBREEDER (
 BREEDER TEXT PRIMARY KEY NOT NULL,
 SITEURL TEXT NULL,
 COUNTRY TEXT NULL
);

--
                                
DROP TABLE IF EXISTS MBREED;

CREATE TABLE MBREED (
 EMS3 TEXT PRIMARY KEY NOT NULL,
 BREED_EN TEXT NOT NULL,
 BREED_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MCOUNTRY;

CREATE TABLE MCOUNTRY (
 COUNTRY TEXT PRIMARY KEY NOT NULL,
 COUNTRY_EN TEXT NOT NULL,
 COUNTRY_FI TEXT NOT NULL
);

--

DROP TABLE IF EXISTS MNEWS;

CREATE TABLE MNEWS (
 DT INTEGER PRIMARY KEY NOT NULL,
 TITLE_EN TEXT NOT NULL,
 TEXT_EN TEXT NOT NULL,
 TITLE_FI TEXT NOT NULL,
 TEXT_FI TEXT NOT NULL
);

--
