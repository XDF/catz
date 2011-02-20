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

-----

drop table if exists _fid_x;

create table _fid_x (
 x integer primary key not null,
 fid integer not null
);

create index _fid_x_1 on _fid_x(fid);

insert into _fid_x (fid) 
select fid from flesh natural join section order by s,n;

-----

drop table if exists _x_photo;

create table _x_photo (
 x integer primary key not null,
 folder text not null,
 file_hr text not null,
 width_hr integer not null,
 height_hr integer not null,
 bytes_hr integer not null,
 file_lr text not null,
 width_lr integer not null,
 height_lr integer not null,
 bytes_lr integer not null
);

insert into _x_photo 
select x,album as folder,file||'.JPG' as file_hr,
width_hr,height_hr,bytes_hr,file||'_LR.JPG' as file_lr,
width_lr,height_lr,bytes_lr from _fid_x natural join 
flesh natural join photo;

-----

drop table if exists _class_pri_sec_x;

create table _class_pri_sec_x (
 class text, sort_class text, pri text ,sort_pri text, sec_en text, sort_en text,
 sec_fi text, sort_fi text, x integer);

create index _class_pri_sec_x_1 on _class_pri_sec_x(pri,sec_en);
create index _class_pri_sec_x_2 on _class_pri_sec_x(pri,sec_fi);
create index _class_pri_sec_x_3 on _class_pri_sec_x(x);

insert into _class_pri_sec_x 
select 'group','02','album','03',name_en,s,name_fi,s,x
from section natural join album natural join flesh natural join _fid_x;

insert into _class_pri_sec_x 
select 'group','02','date','04',
substr(origined,1,4)||'-'||substr(origined,5,2)||'-'||substr(origined,7,2),origined,
round(substr(origined,7,2))||'.'||round(substr(origined,5,2))||'.'||substr(origined,1,4),origined,x
from section natural join album natural join flesh natural join _fid_x
where origined > 1 and origined < 99999999;

insert into _class_pri_sec_x
select 'data','01',area,'00',part,part,part,part,x
from part natural join snip_part natural join line_snip
natural join flesh_line natural join _fid_x;


drop table if exists _pri_sec_meta;

create table _pri_sec_meta_en (
 sort_class text, pri text ,sort_pri text, sec_en text, sort_en text,
 sec_fi text, sort_fi text, x integer);

------------------

select class,pri,count(distinct sec_en)
from _class_pri_sec_x
group by class,pri
order by sort_class,sort_en;

select x from _class_pri_sec_x where
pri='cat' and sec_en like '%s%';

-- 250 ms

select x from _class_pri_sec_x where
pri='cat' and sec_en like 'S%';

-- 110 ms


=================
--



--

drop table if exists _x_photo;

create table _x_photo (
 x integer primary key not null,
 folder text not null,
 file_hr text not null,
 width_hr integer not null,
 height_hr integer not null,
 bytes_hr integer not null,
 file_lr text not null,
 width_lr integer not null,
 height_lr integer not null,
 bytes_lr integer not null
);

insert into _x_photo 
select x,album as folder,file||'.JPG' as file_hr,
width_hr,height_hr,bytes_hr,file||'_LR.JPG' as file_lr,
width_lr,height_lr,bytes_lr from _x_fid natural join 
flesh natural join photo;

--

drop table if exists _item;

create table _item ( 
 iid integer primary key,
 class text not null,
 pri text not null,
 sort_pri integer not null,
 sec_en text not null,
 sort_en text not null,
 sec_fi text not null,
 sort_fi text not null,
 n integer null,
 dt_from null,
 dt_to null
);

create index _item_ix1 on _item(class);
create index _item_ix2 on _item(pri);
create index _item_ix3 on _item(pri,sec_en);
create index _item_ix4 on _item(pri,sec_fi);

--

drop table if exists _x_item;

create table _x_item (
 iid integer not null,
 xid integer not null
);

create index _x_item_ix1 on _x_item(iid);
create index _x_item_ix2 on _x_item(xid);

--

insert into _item (class,pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi)
select 'data',area,1,part,part,part,part from part 
where area='cat' group by part;

insert into _item (class,pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi)
select 'data',area,2,part,part,part,part from part 
where area='breeder' group by part;

insert into _item (class,pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi)
select 'data',area,3,part,part,part,part from part 
where area='nick' group by part;

insert into _item (class,pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi)
select 'data',area,4,part,part,part,part from part 
where area='ems1' group by part union all
select 'data',area,5,part,part,part,part from part 
where area='ems3' group by part union all
select 'data',area,6,part,part,part,part from part 
where area='ems4' group by part union all
select 'data',area,7,part,part,part,part from part 
where area='ems5' group by part;

insert into _x_item
select iid,fid from part natural join snip_part 
natural join line_snip natural join flesh_line 
inner join _item on (area=pri and sec_en=part);

update _item set n = ( 
 select count(distinct xid) from
 _x_item where _x_item.iid = _item.iid
);

--

insert into _item (class,pri,sort_pri,sec_en,sort_en,sec_fi,sort_fi,n)
select 'data','album',8,name_en,s,name_fi,s,count(distinct fid)
from section natural join album natural join flesh
group by flesh.album;

insert into _x_item
select iid,xid from _x_fid natural join flesh natural join album 
inner join _item on (sec_en=name_en) where pri='album'; 

--
-- TESTING
--

select xid from _x_item 
where iid in (
 select iid from _item where 
  (pri='cat' and sec_En like 'Mimo%') or
  (pri='breeder' and sec_En like 'Ipe%')
)
group by xid order by xid;

-- svector on two indexed rules 20 ms 604 results

select xid from _x_item 
where iid in (
 select iid from _item where 
  (pri='cat' and sec_En like 'o%') or
  (pri='breeder' and sec_En like 's%') or
  (pri='ems1' and sec_en = 'n' ) or
  (pri='ems3' and sec_en like 'T' )
)
group by xid order by xid;

-- svector on four indexed rules 110 ms 10518 results

select xid from _x_item 
where iid in (
 select iid from _item where 
  (pri='cat' and sec_En like '%o%') or
  (pri='breeder' and sec_En like '%s%') or
  (pri='ems1' and sec_en like 'n_' ) or
  (pri='ems3' and sec_en like 'T__' )
)
group by xid order by xid;

-- svector on four nonindexed rules 280 ms 25257 results

select sum(n) from _item where 
 (pri='cat' and sec_En like '%o%') or
 (pri='breeder' and sec_En like '%s%') or
 (pri='ems1' and sec_en = 'n_' ) or
 (pri='ems3' and sec_en like 'T__' );
 
-- sum on n 30 ms

select sum(n) from _item where 
 (pri='album' and sec_En like '%surok%');

select xid from _x_item 
where iid in (
 select iid from _item where 
  ((pri='cat' and sec_En like '%o%') or
  (pri='breeder' and sec_En like '%s%') or
  (pri='ems1' and sec_en like 'n_' ) or
  (pri='ems3' and sec_en like 'T__' )) and 
  (pri='album' and sec_En like '%surok%');
)
group by xid order by xid;

  