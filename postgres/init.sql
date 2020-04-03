/* Database setup for reminders */
create database reminders;

/* Change to the new database */
\c reminders

/* The type of event */
CREATE TABLE event_types (
	id serial PRIMARY KEY,
	name varchar(50)
);

/* The clients, who are interested in receiving email reminders */
create table users (
	id serial primary key,
	name varchar(50),
	email varchar(50)
);

/* The list of events - each event has a name and a type */
create table events (
	id serial primary key,
	name varchar(50),
	date date,
	event_type int references event_types(id)
);

/* List of reminders. Each entry has an event and a user who is interested */
create table reminders (
	id serial primary key,
	event_id int references events(id),
	user_id int references users(id)
);

/* Set up some default data */

insert into event_types (name) values ('Anniversary'),('Birthday'),('Death');

/* Function to calculate days to go for an event */
create function days_to_go(val date) returns int as $$
declare
	theyear integer;
	themonth integer;
	theday integer;
	currentyear integer;
	testdate date;
	togo integer;
begin
	theyear := EXTRACT(YEAR from val);
	themonth := EXTRACT(month from val);
	theday := extract(day from val);
	currentyear := extract(year from now());
	testdate := make_date(currentyear, themonth, theday);
	togo := extract(days from (testdate - now()));
	if togo < 0 then
		testdate := make_date(currentyear + 1, themonth, theday);
		togo := extract(days from (testdate - now()));
	end if;
	return togo;
end; $$
language PLPGSQL;

/* Function to return the number of years the event anniversary will be 
   Returns -1 if the year is not known (i.e. the year field is 0001) */
create function years(val date) returns int as $$
declare
	theyear int;
	theresult int = -1;
begin
	theyear = extract(year from val);
	if theyear <> 0001 then
		theresult = date_part('year', now()) - theyear;
	end if;
	return theresult;
end; $$
language plpgsql;
/* Custom View */
create view reminder_list as
	select e."name" as "Event Name", t.name as "Event", u.email as "User Email", 
	e."date" as "Event Date", days_to_go(e."date") as "Days To Go",
	years(e."date") as "Year Count"
	from reminders as r
	inner join events as e on r.event_id = e.id
	inner join event_types as t on e.event_type = t.id
	inner join users as u on r.user_id  = u.id
;

/* Finally, add some test data */
insert into events (name, date, event_type) values
('Greg', '1968-10-15', 2),
('Julia', '1969-05-20', 2),
('Greg & Julia', '2002-05-18', 1),
('Test Jan', '0001-01-01', 2),
('Test Apr', '2020-04-01', 2)
;
insert into users (name, email) values
('Greg', 'greg_wallis@mac.com'),
('Julia', 'julia_wallis@mac.com')
;

insert into reminders (event_id, user_id) values
(1, 2), /* Remind Julia of Greg's Birthday */
(2, 1), /* Remind Greg of Julia's Birthday */
(3, 1), /* Remind Greg of our anniversary */
(3, 2), /* Remind Julia of our anniversary */
(4, 1), /* Test for undated 1st Jan */
(5, 1)  /* Test for 1st Apr */
;

