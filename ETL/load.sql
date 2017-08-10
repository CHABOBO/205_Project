-- Usage:
-- Run psql: psql -U postgres
-- Execute the script: \i /home/w205/205_Project/ETL/load.sql

-- Load:
-- After creating the schema, the data is loaded from csv files in /home/w205/205_Project/ETL
-- Make sure the extract_transform.sh process has been completed first to generate those files

-- Partitioning:
-- We decided to implement partitioning. Although the data set we are currently using is not very large it is open ended, meaning
-- that data for subsequent years will be added to the tables over time. We want performance to remain stable as data increases.
-- Since most of our queries gather data per state, we implemented 5 range partitions with the states divided evenly.
-- Using state for the partition range also means that new years of data can be added without repartitioning.


DROP DATABASE w205project;
CREATE DATABASE w205project WITH OWNER = postgres;

\c w205project

-- Define the year data type with constraints on possible values
CREATE DOMAIN year AS integer
        CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));
ALTER DOMAIN public.year OWNER TO postgres;

CREATE PROCEDURAL LANGUAGE plpgsql;
ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;
SET search_path = public, pg_catalog;

-- Common Core of Data Fiscal data
CREATE TABLE fiscal (
    survey_year year NOT NULL,
    state character varying(2) NOT NULL,
    state_revenue numeric NOT NULL,
    local_revenue numeric NOT NULL,
    federal_revenue numeric NOT NULL,
    total_revenue numeric NOT NULL CHECK (total_revenue > 0),
    teacher_salaries numeric NOT NULL,
    teacher_benefits numeric NOT NULL,
    current_expenditures numeric NOT NULL,
    PRIMARY KEY (survey_year, state)
);
ALTER TABLE public.fiscal OWNER TO postgres;

CREATE TABLE fiscal_1 (
    CHECK ( state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) 
) INHERITS (fiscal);
ALTER TABLE fiscal_1 OWNER TO postgres;
CREATE TABLE fiscal_2 (
    CHECK ( state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) 
) INHERITS (fiscal);
ALTER TABLE fiscal_2 OWNER TO postgres;
CREATE TABLE fiscal_3 (
    CHECK ( state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) 
) INHERITS (fiscal);
ALTER TABLE fiscal_3 OWNER TO postgres;
CREATE TABLE fiscal_4 (
    CHECK ( state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) 
) INHERITS (fiscal);
ALTER TABLE fiscal_4 OWNER TO postgres;
CREATE TABLE fiscal_5 (
    CHECK ( state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) 
) INHERITS (fiscal);
ALTER TABLE fiscal_5 OWNER TO postgres;

CREATE OR REPLACE FUNCTION fiscal_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) THEN
        INSERT INTO fiscal_1 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) THEN
        INSERT INTO fiscal_2 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) THEN
        INSERT INTO fiscal_3 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) THEN
        INSERT INTO fiscal_4 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) THEN
        INSERT INTO fiscal_5 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'State out of range: fiscal_insert_trigger() function';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_fiscal_trigger
    BEFORE INSERT ON fiscal
    FOR EACH ROW EXECUTE PROCEDURE fiscal_insert_trigger();

-- Common Core of Data nonfiscal data
CREATE TABLE nonfiscal (
    survey_year year NOT NULL,
    state character varying(2) NOT NULL,
    total_teachers numeric NOT NULL CHECK (total_teachers > 0),
    grade8_students integer NOT NULL CHECK (grade8_students > 0),
    total_students integer NOT NULL CHECK (total_students > 0),
    PRIMARY KEY (survey_year, state)
);
ALTER TABLE public.nonfiscal OWNER TO postgres;

CREATE TABLE nonfiscal_1 (
    CHECK ( state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) 
) INHERITS (nonfiscal);
ALTER TABLE nonfiscal_1 OWNER TO postgres;
CREATE TABLE nonfiscal_2 (
    CHECK ( state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) 
) INHERITS (nonfiscal);
ALTER TABLE nonfiscal_2 OWNER TO postgres;
CREATE TABLE nonfiscal_3 (
    CHECK ( state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) 
) INHERITS (nonfiscal);
ALTER TABLE nonfiscal_3 OWNER TO postgres;
CREATE TABLE nonfiscal_4 (
    CHECK ( state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) 
) INHERITS (nonfiscal);
ALTER TABLE nonfiscal_4 OWNER TO postgres;
CREATE TABLE nonfiscal_5 (
    CHECK ( state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) 
) INHERITS (nonfiscal);
ALTER TABLE nonfiscal_5 OWNER TO postgres;

CREATE OR REPLACE FUNCTION nonfiscal_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) THEN
        INSERT INTO nonfiscal_1 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) THEN
        INSERT INTO nonfiscal_2 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) THEN
        INSERT INTO nonfiscal_3 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) THEN
        INSERT INTO nonfiscal_4 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) THEN
        INSERT INTO nonfiscal_5 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'State out of range: nonfiscal_insert_trigger() function';
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER insert_nonfiscal_trigger
    BEFORE INSERT ON nonfiscal
    FOR EACH ROW EXECUTE PROCEDURE nonfiscal_insert_trigger();

-- National Assessment of Educational Progess 
-- Grade 8 Mathematics and Reading results
CREATE TABLE naep8 (
    test_year year NOT NULL,
    state character varying(2) NOT NULL,
    math_score numeric CHECK (math_score >= 0 AND math_score <= 500),
    reading_score numeric CHECK (reading_score >= 0 AND reading_score <= 500),
    PRIMARY KEY (test_year, state)
);
ALTER TABLE public.naep8 OWNER TO postgres;

CREATE TABLE naep8_1 (
    CHECK ( state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) 
) INHERITS (naep8);
ALTER TABLE naep8_1 OWNER TO postgres;
CREATE TABLE naep8_2 (
    CHECK ( state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) 
) INHERITS (naep8);
ALTER TABLE naep8_2 OWNER TO postgres;
CREATE TABLE naep8_3 (
    CHECK ( state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) 
) INHERITS (naep8);
ALTER TABLE naep8_3 OWNER TO postgres;
CREATE TABLE naep8_4 (
    CHECK ( state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) 
) INHERITS (naep8);
ALTER TABLE naep8_4 OWNER TO postgres;
CREATE TABLE naep8_5 (
    CHECK ( state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) 
) INHERITS (naep8);
ALTER TABLE naep8_5 OWNER TO postgres;

CREATE OR REPLACE FUNCTION naep8_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.state IN ( 'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL' )) THEN
        INSERT INTO naep8_1 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME' )) THEN
        INSERT INTO naep8_2 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH' )) THEN
        INSERT INTO naep8_3 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI' )) THEN
        INSERT INTO naep8_4 VALUES (NEW.*);
    ELSIF ( NEW.state IN ( 'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY' )) THEN
        INSERT INTO naep8_5 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'State out of range: naep8_insert_trigger() function';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_naep8_trigger
    BEFORE INSERT ON naep8
    FOR EACH ROW EXECUTE PROCEDURE naep8_insert_trigger();

-- Query optimization. Ensure only partitions matching the check constraint are searched.
SET constraint_exclusion = partition;

-- Import the fiscal data from csv file

COPY fiscal 
(     	
survey_year,state,state_revenue,local_revenue,federal_revenue,total_revenue,teacher_salaries,teacher_benefits,current_expenditures
)  
FROM '/home/w205/205_Project/ETL/fiscal.csv'
DELIMITER ',' CSV;

-- Import the nonfiscal data from csv file

COPY nonfiscal 
( 
survey_year,state,total_teachers,grade8_students,total_students    	
)  
FROM '/home/w205/205_Project/ETL/nonfiscal.csv'
DELIMITER ',' CSV;

-- Import the test score data from csv file

COPY naep8 
( 
test_year,state,math_score,reading_score
)  
FROM '/home/w205/205_Project/ETL/naep8.csv'
DELIMITER ',' CSV;

