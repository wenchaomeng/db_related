
create table town(name varchar(100), state_num int not null, desc varchar(1024)); 
create table people(name varchar(100), state_num int not null, desc varchar(1024));
PARTITION TABLE town ON COLUMN state_num;
PARTITION TABLE people ON COLUMN state_num;


CREATE PROCEDURE people_ins  PARTITION ON TABLE people COLUMN state_num AS INSERT INTO people (name, state_num, desc) VALUES (?,?,?);
create index people_name on people(name);
