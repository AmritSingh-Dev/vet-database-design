-- Doctor ID: Must follow the format 22xx (2200-2299).
-- Nurse ID: Must follow the format 33xx (3300-3399).
-- Pet ID: Must be within the range of 1000-3000 inclusive.
-- Consultation ID: Must follow the format 105xxx, starting at 105000 and incrementing sequentially.
-- Email Addresses: Doctor, Nurse, and Receptionist emails must be unique and use the domain @noahs.com.
-- Telephone Numbers: Doctor & Nurse telephone numbers must be unique.
-- Date: Appointments only on Mondays and Fridays.  
-- Pet Age: 0-12 years inclusive.
-- Pet Gender: “M” (Male) or “F” (Female).
-- Doctor: “Full Time” or “Part Time”.
-- Nurse: “Full Time” or “Part Time”.
-- Receptionist: “Full Time” or “Part Time”.

-- DROP ALL TABLES --
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE payment CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE prescription CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE deferral CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE referral CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE nurse_attendance CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE diagnosis CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE consultation CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE pet CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE pharmacy CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE medication CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE specialist CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE nurse CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE doctor CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE client CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/


-- CREATE TABLES --
CREATE TABLE client (
    client_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    first_name VARCHAR2(30) NOT NULL,
    last_name VARCHAR2(35) NOT NULL, -- Allows for double and triple-barreled names
    address VARCHAR2(400) NOT NULL,
    balance NUMBER(6, 2) DEFAULT 0,
    
    CONSTRAINT pk_client PRIMARY KEY (client_id)
    -- No client restrictions, can have as many pets as they want
);

CREATE TABLE doctor (
    doctor_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 2200 INCREMENT BY 1,
    first_name VARCHAR2(30) NOT NULL,
    last_name VARCHAR2(50) NOT NULL, -- Allows for double and triple-barreled names
    office_number NUMBER, -- Can be null, may have just joined practice
    telephone_number VARCHAR2(13) UNIQUE NOT NULL, -- UK phone numbers
    email_address VARCHAR2(100) UNIQUE NOT NULL, 
    employment_status VARCHAR2(10) NOT NULL CHECK (employment_status IN ('full-time', 'part-time')),
    
    CONSTRAINT pk_doctor PRIMARY KEY (doctor_id),
    CONSTRAINT doctor_email_format CHECK (email_address LIKE '%@noahs.com'), -- Enforce @noahs.com format
    CONSTRAINT doctor_id_format CHECK (doctor_id BETWEEN 2200 AND 2299) -- Enforce doctor_id format
);

CREATE TABLE nurse (
    nurse_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 3300 INCREMENT BY 1,
    first_name VARCHAR2(30) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    office_number NUMBER DEFAULT 2,
    employment_status VARCHAR2(10) NOT NULL CHECK (employment_status IN ('full-time', 'part-time')),
    telephone_number VARCHAR2(13) UNIQUE NOT NULL,
    
    CONSTRAINT pk_nurse PRIMARY KEY (nurse_id),
    CONSTRAINT nurse_id_format CHECK (nurse_id BETWEEN 3300 AND 3399) -- Enforce nurse_id format
);

CREATE TABLE specialist (
    specialist_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    address VARCHAR2(300) NOT NULL, 
    first_name VARCHAR2(50) NOT NULL, 
    last_name VARCHAR2(50) NOT NULL,
    
    CONSTRAINT pk_specialist PRIMARY KEY (specialist_id)
);

CREATE TABLE medication (
    medication_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,  -- No limit, new medications are released often
    name VARCHAR2(100) NOT NULL,
    cost NUMBER(6, 2),
    
    CONSTRAINT pk_medication PRIMARY KEY (medication_id)
);

CREATE TABLE pharmacy(
    pharmacy_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
	name VARCHAR2(100) NOT NULL,
	address VARCHAR2(400) NOT NULL,
    
    CONSTRAINT pk_pharmacy PRIMARY KEY (pharmacy_id)
);

CREATE TABLE pet (
    pet_id NUMBER(4) GENERATED ALWAYS AS IDENTITY START WITH 1000 INCREMENT BY 1,
    name VARCHAR(20) NOT NULL,
    animal VARCHAR2(30) NOT NULL,
    breed VARCHAR2(100) DEFAULT 'N/A' NOT NULL, -- Default to N/A if breed is not known
    gender CHAR(1) NOT NULL,
    age NUMBER(2) NOT NULL,
    colour VARCHAR2(30) NOT NULL,
    weight NUMBER(4, 2) NOT NULL, -- Kilograms
    client_id NUMBER(4) NOT NULL,
    
    CONSTRAINT pk_pet PRIMARY KEY (pet_id),
    CONSTRAINT pet_age_range CHECK (age BETWEEN 0 AND 12),
    CONSTRAINT pet_gender_range CHECK (gender IN('M', 'F')),
    CONSTRAINT pet_id_range CHECK (pet_id BETWEEN 1000 AND 3000),
    CONSTRAINT pet_weight_range CHECK (weight > 0),
    CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES client(client_id)
);

CREATE TABLE consultation (
    consultation_id NUMBER(6) GENERATED ALWAYS AS IDENTITY START WITH 105000 INCREMENT BY 1,
    date_time TIMESTAMP(0) NOT NULL, -- Stores both date and time
    client_attended CHAR(1) CHECK (client_attended IN ('Y', 'N')), -- Use CHAR(1) for BOOLEAN, Can be null b/c consultation date may not have happened yet
    visit_fee NUMBER(4, 2) CHECK (visit_fee IN (10, 15, 20)),
    cancellation_fee_paid CHAR(1) NOT NULL CHECK (cancellation_fee_paid IN ('Y', 'N')),
    needs_follow_up CHAR(1) NOT NULL CHECK (needs_follow_up IN ('Y', 'N')), -- Use CHAR(1) for BOOLEAN
    doctor_id NUMBER(4) NOT NULL,
    pet_id NUMBER(4) NOT NULL,
    followed_up_cons_id NUMBER(6),
    
    CONSTRAINT pk_consultation PRIMARY KEY (consultation_id),
    CONSTRAINT fk_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id),
    CONSTRAINT fk_pet FOREIGN KEY (pet_id) REFERENCES pet(pet_id),
    CONSTRAINT fk_followed_up_cons FOREIGN KEY (followed_up_cons_id) REFERENCES consultation(consultation_id),
    CONSTRAINT consultation_day_restrictions CHECK (TO_CHAR(date_time, 'DY') IN ('MON', 'FRI')), -- Verifies consultations occur only on Mondays and Fridays
    CONSTRAINT consultation_time_restrictions CHECK (TO_CHAR(date_time, 'HH24:MI') >= '09:00' AND TO_CHAR(date_time, 'HH24:MI') <= '17:00') -- Verifies consultations occur between 9AM and 5PM
);


CREATE TABLE diagnosis (
    diagnosis_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1, -- No limit, need to store complete diagnosis history 
    is_conclusive CHAR(1) CHECK (is_conclusive IN ('Y', 'N')), -- Use CHAR(1) for BOOLEAN
    condition VARCHAR2(100), -- Can be null due to inconclusive diagnosis
    description VARCHAR2(1500),
    consultation_id NUMBER(6) NOT NULL,
    
    CONSTRAINT pk_diagnosis PRIMARY KEY (diagnosis_id),
    CONSTRAINT fk_consultation_diagnosis FOREIGN KEY (consultation_id) REFERENCES consultation(consultation_id)
);

CREATE TABLE nurse_attendance (
    nurse_id NUMBER(4) NOT NULL,
    consultation_id NUMBER(6) NOT NULL,

    CONSTRAINT pk_nurse_attendance PRIMARY KEY (nurse_id, consultation_id), -- Composite primary key
    CONSTRAINT fk_nurse FOREIGN KEY (nurse_id) REFERENCES nurse(nurse_id),
    CONSTRAINT fk_consultation_nurse_att FOREIGN KEY (consultation_id) REFERENCES consultation(consultation_id)
);

CREATE TABLE referral (
    diagnosis_id NUMBER NOT NULL, -- Not null, has to be associated with a diagnosis
    specialist_id NUMBER(4) NOT NULL,
    description VARCHAR2(2000),
    
    CONSTRAINT pk_referral PRIMARY KEY (diagnosis_id, specialist_id), -- Composite primary key
    CONSTRAINT fk_diagnosis FOREIGN KEY (diagnosis_id) REFERENCES diagnosis(diagnosis_id),
    CONSTRAINT fk_specialist FOREIGN KEY (specialist_id) REFERENCES specialist(specialist_id)
);

CREATE TABLE deferral (
    consultation_id NUMBER(6) NOT NULL,
    diagnosis_id NUMBER NOT NULL, -- Not null, has to be associated with a (inconclusive) diagnosis
    description VARCHAR2(1500),
    
    CONSTRAINT pk_deferral PRIMARY KEY (consultation_id, diagnosis_id), -- Composite primary key
    CONSTRAINT fk_consultation FOREIGN KEY (consultation_id) REFERENCES consultation(consultation_id),
    CONSTRAINT fk_diagnosis_deferral FOREIGN KEY (diagnosis_id) REFERENCES diagnosis(diagnosis_id)
);

CREATE TABLE prescription (
    prescription_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1, -- No limit, need to store all prescription history 
    diagnosis_id NUMBER NOT NULL,
    medication_id NUMBER NOT NULL,
    pharmacy_id NUMBER NOT NULL,
    
    CONSTRAINT pk_prescription PRIMARY KEY (prescription_id),
    CONSTRAINT fk_diagnosis_prescription FOREIGN KEY (diagnosis_id) REFERENCES diagnosis(diagnosis_id),
    CONSTRAINT fk_medication FOREIGN KEY (medication_id) REFERENCES medication(medication_id),
    CONSTRAINT fk_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES pharmacy(pharmacy_id)
);

CREATE TABLE payment (
    payment_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1, -- No limit, need to store complete payment history 
	amount NUMBER(6, 2) NOT NULL CHECK(amount >= 0), -- Allows free vouchers
    date_time TIMESTAMP(0) NOT NULL, -- Stores date and time of the payment
    consultation_id NUMBER(6) NOT NULL, -- Links payment to a consultation
    
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_cons FOREIGN KEY (consultation_id) REFERENCES consultation(consultation_id)
);

-- INSERTING OF ALL RECORDS -- 

-- CLIENT RECORDS --
INSERT INTO client(first_name, last_name, address, balance)
    VALUES (
        'David', 
        'Smith', 
        '123 Main Street, Salford, Manchester, M7 1AA', 
        25);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'Sam', 
        'Stones', 
        '22 Whitworth Street, Manchester, M1 1TS');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Craig', 
        'Bennet', 
        '27 Oak Lane, Didsbury, Manchester, M20 6RF',
         10);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'George', 
        'Best', 
        '152 Elm Road, Chorlton, Manchester, M21 9QZ');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Kylie', 
        'Lock', 
        '98 Birch Avenue, Sale, Manchester, M33 3AX', 
        55);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'Chabbu', 
        'Patel', 
        '45 Willow Park, Prestwich, Manchester, M25 3DS');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Sarah', 
        'Heys', 
        '63 Pine Street, Salford, Manchester, M6 5PL', 
        40);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'Gabby', 
        'Solomon', 
        '12 Cedar Crescent, Withington, Manchester, M20 4BX');


INSERT INTO client (first_name, last_name, address, balance)
    VALUES (
        'Carl', 
        'Johnson', 
        '86 Maple Drive, Swinton, Manchester, M27 0FL', 
        100);


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Steve', 
        'Lock', 
        '12 Cedar Crescent, Withington, Manchester, M20 4BX', 
        1000);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'Stacey', 
        'Madeen', 
        '34 Alder Road, Fallowfield, Manchester, M14 6WG');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Vincent', 
        'Kompany', 
        '71 Beech Road, Levenshulme, Manchester, M19 3AP', 
        85);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'John', 
        'Stones', 
        '15 Oakwood Avenue, Eccles, Manchester, M30 9JH');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Michelle', 
        'Wade', 
        '22 Hazel Court, Stretford, Manchester, M32 0JT', 
        90);


INSERT INTO client (first_name, last_name, address) 
    VALUES (
        'Shirley', 
        'Farmer', 
        '89 Linden Grove, Denton, Manchester, M34 7GL');


INSERT INTO client (first_name, last_name, address, balance) 
    VALUES (
        'Sharon', 
        'Courts', 
        '53 Ashwood Terrace, Urmston, Manchester, M41 9PT', 
        15);


-- PET RECORDS --
INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'chappyDog',
        'Dog',
        'Alsation',
        'M',
        2,
        'Beige',
        3.0,
        1);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'chiwado',
        'Dog',
        'Chiwawa',
        'F',
        10,
        'Black',
        1,
        2);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'bullyTom',
        'Dog',
        'Bulldog',
        'F',
        6,
        'Grey',
        4.5,
        3);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'terryToe',
        'Dog',
        'Terrier',
        'F',
        4,
        'White',
        1.2,
        4);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'poody',
        'Dog',
        'Boxer',
        'M',
        8,
        'Black',
        1,
        5);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'dood',
        'Dog',
        'Dalmation',
        'F',
        3,
        'Spotted White',
        7,
        6);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'dood',
        'Dog',
        'Sheep Wolf',
        'M',
        11,
        'Brown',
        10,
        7);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'labbyDee',
        'Dog',
        'Labrador',
        'M',
        12,
        'White',
        11,
        5);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'shiTzo',
        'Dog',
        'Shih Tzu',
        'F',
        7,
        'Mixed Brown',
        1,
        5);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'jake',
        'Dog',
        'Jack Russell',
        'M',
        3,
        'Greyish White',
        4,
        10);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'gotty',
        'Dog',
        'Golden Retriever',
        'M',
        4,
        'Greyish White',
        1,
        5);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'maisy',
        'Cat',
        'Burmese',
        'F',
        7,
        'Brown',
        4,
        11);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'rex',
        'Dog',
        'German Shepherd',
        'M',
        5,
        'Tan',
        14.4,
        12);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'bella',
        'Dog',
        'Poodle',
        'F',
        3,
        'White',
        6.5,
        13);

INSERT INTO pet(name, animal, gender, age, colour, weight, client_id) -- Adding unknown breed (rabbit)
    VALUES(
        'whiskers',
        'Rabbit',
        'M',
        2,
        'Cream ',
        1.7,
        14);

INSERT INTO pet(name, animal, gender, age, colour, weight, client_id) -- Adding an unknown breed (stray dog)
    VALUES(
        'buster',
        'Dog',
        'M',
        4,
        'Light Brown',
        9.5,
        15);

INSERT INTO pet(name, animal, breed, gender, age, colour, weight, client_id)
    VALUES(
        'toby',
        'Dog',
        'Cocker Spaniel',
        'M',
        5,
        'Golden',
        12.5,
        16);

-- DOCTOR RECORDS --
INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Clive',
        'Cleverly',
        12,
        '0161-111-1111',
        'cleverly_cl@noahs.com',
        'part-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Mike',
        'Kershaw',
        34,
        '0161-112-1212',
        'mikeK@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Fiona',
        'Farraday',
        34,
        '0161-113-1313',
        'farradayF@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Fred',
        'Feeles',
        41,
        '0161-114-1414',
        'fredF@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Sophie',
        'Watson',
        1,
        '0161-115-1515',
        'watsS@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Fillip',
        'Freeman',
        2,
        '0161-116-1616',
        'freemanF@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Celia',
        'Crowley',
        10,
        '0161-117-1717',
        'crowleyC@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Rahib',
        'Brev',
        16,
        '0161-118-1818',
        'rahibB@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Aoife',
        'McQuaid',
        24,
        '0161-119-1919',
        'mcquaidA@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Ross',
        'Geller',
        15,
        '0161-123-4567',
        'rossG@noahs.com',
        'part-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Monica',
        'Geller',
        18,
        '0161-234-5678',
        'monicaG@noahs.com',
        'full-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Joey',
        'Tribbiani',
        30,
        '0161-345-6789',
        'joeyT@noahs.com',
        'part-time');


INSERT INTO doctor(first_name, last_name, office_number, telephone_number, email_address, employment_status)
    VALUES(
        'Chandler',
        'Bing',
        25,
        '0161-456-7890',
        'chandlerB@noahs.com',
        'full-time');

-- NURSE RECORDS --
INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Alice', 
        'Turner', 
        'aliceT@noahs.com', 
        'full-time', 
        '0161-555-0100');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Bob', 
        'Johnson', 
        'bobJ@noahs.com', 
        'part-time', 
        '0161-555-0101');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Cindy', 
        'Smith', 
        'cindyS@noahs.com', 
        'full-time', 
        '0161-555-0102');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'David', 
        'Lee', 
        'davidL@noahs.com', 
        'part-time', 
        '0161-555-0103');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Emily', 
        'Davis', 
        'emilyD@noahs.com', 
        'full-time', 
        '0161-555-0104');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Frank', 
        'Miller', 
        'frankM@noahs.com', 
        'part-time', 
        '0161-555-0105');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Grace', 
        'Wilson', 
        'graceW@noahs.com', 
        'full-time', 
        '0161-555-0106');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Henry', 
        'Moore', 
        'henryM@noahs.com', 
        'part-time', 
        '0161-555-0107');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Isabel', 
        'Taylor', 
        'isabelT@noahs.com', 
        'full-time', 
        '0161-555-0108');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'John', 
        'Brown', 
        'johnB@noahs.com', 
        'part-time', 
        '0161-555-0109');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Katie', 
        'Jones', 
        'katieJ@noahs.com', 
        'full-time', 
        '0161-555-0110');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Liam', 
        'Garcia', 
        'liamG@noahs.com', 
        'part-time', 
        '0161-555-0111');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Monica', 
        'Martinez', 
        'monicaM@noahs.com', 
        'full-time', 
        '0161-555-0112');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Nathan', 
        'Rodriguez', 
        'nathanR@noahs.com', 
        'part-time', 
        '0161-555-0113');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Olivia', 
        'Harris', 
        'oliviaH@noahs.com', 
        'full-time', 
        '0161-555-0114');

INSERT INTO nurse (first_name, last_name, email, employment_status, telephone_number) 
    VALUES (
        'Peter', 
        'Clark', 
        'peterC@noahs.com', 
        'part-time', 
        '0161-555-0115');

-- SPECIALIST RECORDS -- 
INSERT INTO specialist (address, first_name, last_name)
    VALUES (
        '101 Deansgate, Manchester, M3 2BQ', 
        'Eleanor', 
        'Rigby');

INSERT INTO specialist (address, first_name, last_name)
    VALUES (
        '25 Piccadilly, Manchester, M1 1LU', 
        'Oliver', 
        'Morris');

INSERT INTO specialist (address, first_name, last_name)
    VALUES (
        '78 King Street, Manchester, M2 4WU', 
        'Amelia', 
        'Clarke');

INSERT INTO specialist (address, first_name, last_name)
    VALUES (
        '305 Oxford Road, Manchester, M13 9PG', 
        'Lucas', 
        'Graham');

INSERT INTO specialist (address, first_name, last_name)
    VALUES (
        '144 Portland Street, Manchester, M1 4DF', 
        'Sophie', 
        'Turner');

-- MEDICATION RECORDS -- 
INSERT INTO medication (name, cost)
    VALUES (
        'Metacam', -- Anti-inflammatory for dogs and cats
        25.50);


INSERT INTO medication (name, cost)
    VALUES (
        'Carprieve', -- Pain relief and anti-inflammatory for dogs
        20.00);


INSERT INTO medication (name, cost)
    VALUES (
        'Drontal', -- Worming tablet for dogs and cats
        15.75);


INSERT INTO medication (name, cost)
    VALUES (
        'Frontline', -- Flea and tick treatment
        45.10);


INSERT INTO medication (name, cost)
    VALUES (
        'Advocate', -- Parasitic treatment for fleas, worms, and mites
        30.99);


INSERT INTO medication (name, cost)
    VALUES (
        'Fuciderm', 55.25);

INSERT INTO medication (name, cost)
    VALUES (
        'Gabapentin', -- Pain management, particularly for nerve pain in pets
        60.40);


INSERT INTO medication (name, cost)
    VALUES (
        'Loxicom', -- Anti-inflammatory similar to Metacam
        22.50);


INSERT INTO medication (name, cost)
    VALUES (
        'Synulox', -- Broad-spectrum antibiotic for pets
        17.75);


INSERT INTO medication (name, cost)
    VALUES (
        'Thyronorm', -- Treatment for hyperthyroidism in cats
        12.30);


INSERT INTO medication (name, cost)
    VALUES (
        'Salicylic Acid Topical Solution', -- Treatment for overgrown skin
        22.50);


INSERT INTO medication (name, cost)
    VALUES (
        'Hypoallergenic Shampoo', -- Treatment for skin care
        15.90);

-- PHARMRACY RECORDS -- 
INSERT INTO pharmacy (name, address)
    VALUES (
        'Manchester Central Pharmacy', 
        '101 Deansgate, Manchester, M3 2BQ');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Northern Health Pharmacy', 
        '45 Piccadilly, Manchester, M1 1LU');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Oxford Road Pharmacy', 
        '305 Oxford Road, Manchester, M13 9PG');

INSERT INTO pharmacy (name, address)
    VALUES (
        'City Centre Meds', 
        '78 King Street, Manchester, M2 4WU');

INSERT INTO pharmacy (name, address)
    VALUES (
        'East Manchester Pharmacy', 
        '12 Ashton Old Road, Manchester, M11 1JS');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Bridgewater Pharmacy', 
        '60 Bridgewater Street, Manchester, M3 4NF');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Greenwood Community Pharmacy', 
        '22 Greenwood Road, Manchester, M19 1RW');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Didsbury Village Pharmacy', 
        '85 Wilmslow Road, Didsbury, Manchester, M20 5LS');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Fallowfield Care Pharmacy', 
        '120 Wilbraham Road, Fallowfield, Manchester, M14 7DS');

INSERT INTO pharmacy (name, address)
    VALUES (
        'Prestwich Health Hub', 
        '33 Bury Old Road, Prestwich, Manchester, M25 0FT');

-- CONSULTATION RECORDS --
INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-16 10:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2209, 
        1001);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id, followed_up_cons_id)
    VALUES (
        TIMESTAMP '2024-12-20 11:30:00', 
        'Y', 
        10,
        'N',
        'N', 
        2202, 
        1001, 
        105000);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-16 13:00:00', 
        'N', 
        20,
        'Y',
        'Y', 
        2203, 
        1002);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-16 15:30:00', 
        'Y', 
        15,
        'N',
        'N', 
        2204, 
        1003);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP 
        '2024-12-20 09:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2205, 
        1004);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id, followed_up_cons_id)
    VALUES (
        TIMESTAMP '2024-12-20 10:00:00', 
        'Y', 
        10,
        'N',
        'Y', 
        2209, 
        1004, 
        105004);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-16 12:00:00', 
        'Y', 
        20,
        'N',
        'N', 
        2206, 
        1005);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-20 14:00:00', 
        'N', 
        20,
        'Y',
        'N', 
        2207, 
        1006);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-16 16:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2208, 
        1007);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2024-12-20 11:00:00', 
        'Y', 
        20,
        'N',
        'N', 
        2209, 
        1008);


-- Temporarily disabling auto incrementing ID's
ALTER TABLE consultation MODIFY consultation_id GENERATED BY DEFAULT AS IDENTITY;

-- Temporarily disabling day restrictions to insert consultations outside of Mon/Fri constraints
ALTER TABLE consultation DISABLE CONSTRAINT consultation_day_restrictions;

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        105078, 
        TIMESTAMP '2023-09-06 10:00:00', 
        'N', 
        15, 
        'Y',
        'N', 
        2201, 
        1002);

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        105091, 
        TIMESTAMP '2023-09-09 12:00:00', 
        'Y', 
        10, 
        'N',
        'Y', 
        2202, 
        1003);

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        105235, 
        TIMESTAMP '2023-10-07 12:30:00', 
        'Y', 
        20, 
        'N',
        'N', 
        2204, 
        1006);

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        105187, 
        TIMESTAMP '2023-09-29 11:30:00', 
        'Y', 
        10, 
        'N',
        'Y', 
        2200, 
        1000);

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id, followed_up_cons_id)
    VALUES (
        105100,
        TIMESTAMP '2023-09-25 12:00:00', 
        'Y', 
        20, 
        'N',
        'N', 
        2209, 
        1003, 
        105091);

INSERT INTO consultation (consultation_id, date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id, followed_up_cons_id)
    VALUES (
        105206,
        TIMESTAMP '2023-10-06 10:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2200, 
        1000, 
        105187);

-- Reenabling auto incrementing ID's
ALTER TABLE consultation MODIFY consultation_id GENERATED ALWAYS AS IDENTITY;

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-08-05 09:00:00', 
        'Y', 
        10,
        'N',
        'Y', 
        2201, 
        1000);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-08-05 11:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2200, 
        1003);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-08-09 10:00:00', 
        'Y', 
        15,
        'N',
        'N', 
        2201, 
        1004);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-08-16 14:00:00', 
        'Y', 
        15,
        'N',
        'Y', 
        2202, 
        1001);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-10-07 09:30:00', 
        'Y', 
        20,
        'N',
        'N', 
        2204, 
        1006);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-10-11 11:30:00', 
        'Y', 
        15,
        'N',
        'N', 
        2203, 
        1002);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-09-02 10:15:00', 
        'Y', 
        10,
        'N',
        'Y', 
        2206, 
        1005);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-09-06 13:00:00', 
        'N', 
        15,
        'Y',
        'N', 
        2200, 
        1008);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-09-27 15:30:00', 
        'Y', 
        20,
        'N',
        'N', 
        2200, 
        1006);

INSERT INTO consultation (date_time, client_attended, visit_fee, cancellation_fee_paid, needs_follow_up, doctor_id, pet_id)
    VALUES (
        TIMESTAMP '2023-10-04 16:45:00', 
        'Y', 
        20,
        'N',
        'N', 
        2203, 
        1007);

-- Reenabling day constraint
ALTER TABLE consultation ENABLE NOVALIDATE CONSTRAINT consultation_day_restrictions;

-- DIAGNOSIS RECORDS --
INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Fleas', 
        'Pet shows signs of flea infestation.', 
        105000);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Seperation Anxiety', 
        'Needs socialisation treats.', 
        105001);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'N', 
        NULL, 
        'Uncertain about underlying cause.', 
        105002);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'N', 
        NULL, 
        'Further lab tests required.', 
        105003);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Severe Skin Allergy', 
        'Referral to specialist recommended.', 
        105004);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tartar Buildup', 
        'Ultrasonic dental scaling in two weeks.', 
        105005);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tapeworm', 
        'Worming medication prescriped.', 
        105006);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'N', 
        NULL, 
        'Symptoms unclear.', 
        105007);


INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Obesity', 
        'Diet plan and exercise routine advised.', 
        105008);


INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Complex fracture', 
        'Referral to orthopedic specialist required.', 
        105009);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Seperation Anxiety', 
        'Needs socialisation treats.', 
        105078);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tartar Buildup', 
        'Ultrasonic dental scaling in two weeks.', 
        105091);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Overgrown Skin', 
        'Excess skin on feet.', 
        105235);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tapeworm', 
        'Needs socialisation treats & worming treatment.', 
        105187);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tartar Buildup Resolved', 
        'Dental work completed.', 
        105100);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Tapeworm Cured.', 
        'Worming treatment completed.', 
        105206);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Routine Checkup', 
        'Bring him Tuesdays 10 to 12:00pm.', 
        105010);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Prescription Pickup', 
        'Get Drug Fuciderm from Bridgewater Pharmacy.', 
        105011);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Obesity', 
        'Take park walks every evening.', 
        105012);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Pre-operative Assessment', 
        'Surgery on 21-Nov-21.', 
        105013);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Dental Check', 
        'Brush teeth with recommended toothpaste.', 
        105014);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Dietary Check', 
        'Switch to low-fat diet for weight management.', 
        105015);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Vaccination Update', 
        'Annual booster due in 3 months.', 
        105016);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Joint Care', 
        'Prescribe joint supplements and mild exercise.', 
        105017);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Ear Infection Treatment', 
        'Administer ear drops daily for 2 weeks.', 
        105018);

INSERT INTO diagnosis (is_conclusive, condition, description, consultation_id)
    VALUES (
        'Y', 
        'Skin Care', 
        'Use hypoallergenic shampoo weekly.', 
        105019);


-- NURSE ATTENDANCE RECORDS --
INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3300, 
        105000);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3301, 
        105001);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3302, 
        105002);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3303, 
        105003);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3304, 
        105004);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3305, 
        105005);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3306, 
        105006);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3307, 
        105007);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3308, 
        105008);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3309, 
        105009);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3310, 
        105078);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3305, 
        105078);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3311, 
        105091);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3312, 
        105187);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3307, 
        105187);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3313, 
        105235);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3314, 
        105100);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3315, 
        105100);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3302, 
        105206);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3301, 
        105010);
        
INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3302, 
        105010);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3303, 
        105011);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3304, 
        105012);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3305, 
        105012);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3306, 
        105013);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3307, 
        105014);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3308, 
        105014);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3309, 
        105015);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3310, 
        105016);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3311, 
        105016);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3312, 
        105017);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3313, 
        105018);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3314, 
        105018);

INSERT INTO nurse_attendance (nurse_id, consultation_id) 
    VALUES (
        3315, 
        105019);

-- REFERRAL RECORDS --
INSERT INTO referral (diagnosis_id, specialist_id, description)
    VALUES (
        5, 
        1, 
        'Refer to dermatologist for allergy treatment.');

INSERT INTO referral (diagnosis_id, specialist_id, description)
    VALUES (
        10, 
        2, 
        'Orthopedic specialist required for complex fracture.');

INSERT INTO referral (diagnosis_id, specialist_id, description)
    VALUES (
        4, 
        3, 
        'Refer to internal medicine specialist for further evaluation.');


-- DEFERRAL RECORDS --
INSERT INTO deferral (consultation_id, diagnosis_id, description)
    VALUES (
        105002, 
        3, 
        'Symptoms unclear, tests deferred to a later date.');

INSERT INTO deferral (consultation_id, diagnosis_id, description)
    VALUES (
        105003, 
        4, 
        'Lab test results required for further diagnosis.');

INSERT INTO deferral (consultation_id, diagnosis_id, description)
    VALUES (
        105007, 
        8, 
        'Symptoms too vague to proceed.');


-- PRESCRIPTION RECORDS --
INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        1, 
        1, 
        1);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        2, 
        2, 
        2);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        7, 
        3, 
        3);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        5, 
        4, 
        4);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        9, 
        5, 
        5);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        10, 
        6, 
        6);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        5, 
        7, 
        7);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        6, 
        8, 
        8);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        4, 
        9, 
        9);


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        1, 
        10, 
        10);

INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        13, 
        11, 
        5);

INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        14, 
        3, 
        7);

INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        18,
        6,
        6
    );


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        25,
        5,
        3
    );


INSERT INTO prescription (diagnosis_id, medication_id, pharmacy_id)
    VALUES (
        26,
        12,
        4
    );


-- PAYMENT RECORDS --
INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-16 10:15:00', 
        105000);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-20 11:45:00', 
        105001);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-16 13:15:00', 
        105002);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2024-12-16 15:45:00', 
        105003);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-20 09:15:00', 
        105004);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-20 10:15:00', 
        105005);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2024-12-16 12:15:00', 
        105006);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2024-12-20 14:15:00', 
        105007);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2024-12-16 16:15:00', 
        105008);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2024-12-20 11:15:00', 
        105009);


INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2023-09-06 10:30:00', 
        105078);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-09-09 12:30:00', 
        105091);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-09-29 15:00:00', 
        105187);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2023-10-07 13:00:00', 
        105235);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-09-25 12:30:00', 
        105100);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-09-29 12:00:00', 
        105206);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-08-05 09:30:00', 
        105010);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-08-05 11:15:00', 
        105011);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2023-08-09 10:30:00', 
        105012);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2023-08-16 14:15:00', 
        105013);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2023-10-07 09:45:00', 
        105014);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2023-10-11 11:45:00', 
        105015);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        10, 
        TIMESTAMP '2023-09-02 10:30:00', 
        105016);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        15, 
        TIMESTAMP '2023-09-06 13:15:00', 
        105017);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2023-09-27 15:45:00', 
        105018);

INSERT INTO payment (amount, date_time, consultation_id)
    VALUES (
        20, 
        TIMESTAMP '2023-10-04 16:50:00', 
        105019);
