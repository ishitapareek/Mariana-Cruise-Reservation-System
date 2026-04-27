-- Mariana Cruise Reservation System - Master SQL Script
-- Generates everything from scratch

DROP DATABASE IF EXISTS Cruise_Reservation_System;
CREATE DATABASE Cruise_Reservation_System CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE Cruise_Reservation_System;

-- ==================================================
-- FILE: Tables/Personal.sql
-- ==================================================

CREATE TABLE Personal (
  Registration_Id INT AUTO_INCREMENT PRIMARY KEY,
  Full_Name       VARCHAR(200) NOT NULL,
  Email           VARCHAR(200) NOT NULL UNIQUE,
  Mobile_Number   CHAR(10) UNIQUE,
  Password        VARCHAR(255) NOT NULL,
  Address         VARCHAR(255),
  DOB             DATE,
  Gender          VARCHAR(50),
  Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (Email)
);


-- ==================================================
-- FILE: Tables/Ports.sql
-- ==================================================

CREATE TABLE Ports (
  Port_Code INT AUTO_INCREMENT PRIMARY KEY,
  Port_Name VARCHAR(100) NOT NULL,
  City      VARCHAR(45),
  Country   VARCHAR(45)
);


-- ==================================================
-- FILE: Tables/Cruise_Master.sql
-- ==================================================

CREATE TABLE Cruise_Master (
  Cruise_Master_Id INT AUTO_INCREMENT PRIMARY KEY,
  Cruise_Name      VARCHAR(100) NOT NULL,
  Ship_Model       VARCHAR(45),
  Start_Port_Code  INT,
  End_Port_Code    INT,
  FOREIGN KEY (Start_Port_Code) REFERENCES Ports(Port_Code) ON DELETE SET NULL,
  FOREIGN KEY (End_Port_Code)   REFERENCES Ports(Port_Code) ON DELETE SET NULL
);


-- ==================================================
-- FILE: Tables/Cruise_Schedule.sql
-- ==================================================

CREATE TABLE Cruise_Schedule (
  Cruise_Id        INT AUTO_INCREMENT PRIMARY KEY,
  Cruise_Master_Id INT NOT NULL,
  Start_Date       DATE NOT NULL,
  End_Date         DATE NOT NULL,
  Available_Seats  INT DEFAULT 100,
  Price_Base       INT NOT NULL,
  FOREIGN KEY (Cruise_Master_Id) REFERENCES Cruise_Master(Cruise_Master_Id) ON DELETE CASCADE,
  INDEX idx_dates (Start_Date, End_Date)
);


-- ==================================================
-- FILE: Tables/Suites.sql
-- ==================================================

CREATE TABLE Suites (
  Suite_Code    INT AUTO_INCREMENT PRIMARY KEY,
  Suite_Type    VARCHAR(50),
  Price_Per_Day INT NOT NULL,
  Max_Capacity  INT NOT NULL
);


-- ==================================================
-- FILE: Tables/Activities.sql
-- ==================================================

CREATE TABLE Activities (
  Activity_Code INT AUTO_INCREMENT PRIMARY KEY,
  Activity_Name VARCHAR(50),
  Price         INT NOT NULL,
  Max_Capacity  INT
);


-- ==================================================
-- FILE: Tables/Booking_Status.sql
-- ==================================================

CREATE TABLE Booking_Status (
  Status_Id   INT PRIMARY KEY,
  Status_Name VARCHAR(50) UNIQUE
);


-- ==================================================
-- FILE: Tables/Payment_Status.sql
-- ==================================================

CREATE TABLE Payment_Status (
  Status_Id   INT PRIMARY KEY,
  Status_Name VARCHAR(50) UNIQUE
);


-- ==================================================
-- FILE: Tables/Reservation.sql
-- ==================================================

CREATE TABLE Reservation (
  Reservation_Id INT AUTO_INCREMENT PRIMARY KEY,
  User_Id        INT NOT NULL,
  Cruise_Id      INT NOT NULL,
  Status_Id      INT NOT NULL,
  Members        INT NOT NULL,
  Created_At     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (User_Id)   REFERENCES Personal(Registration_Id) ON DELETE CASCADE,
  FOREIGN KEY (Cruise_Id) REFERENCES Cruise_Schedule(Cruise_Id) ON DELETE CASCADE,
  FOREIGN KEY (Status_Id) REFERENCES Booking_Status(Status_Id),
  INDEX idx_user (User_Id),
  INDEX idx_cruise (Cruise_Id)
);


-- ==================================================
-- FILE: Tables/Passengers.sql
-- ==================================================

CREATE TABLE Passengers (
  Passenger_Id   INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Full_Name      VARCHAR(100),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE
);


-- ==================================================
-- FILE: Tables/User_Suites.sql
-- ==================================================

CREATE TABLE User_Suites (
  Reservation_Id INT,
  Suite_Code     INT,
  Nights         INT DEFAULT 1,
  PRIMARY KEY (Reservation_Id, Suite_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Suite_Code)     REFERENCES Suites(Suite_Code)
);


-- ==================================================
-- FILE: Tables/User_Activities.sql
-- ==================================================

CREATE TABLE User_Activities (
  Reservation_Id INT,
  Activity_Code  INT,
  PRIMARY KEY (Reservation_Id, Activity_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Activity_Code)  REFERENCES Activities(Activity_Code)
);


-- ==================================================
-- FILE: Tables/Payment.sql
-- ==================================================

CREATE TABLE Payment (
  Transaction_Id INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Amount         INT,
  Status_Id      INT,
  Created_At     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id),
  FOREIGN KEY (Status_Id)      REFERENCES Payment_Status(Status_Id)
);


-- ==================================================
-- FILE: Functions/Get_Total_Cost.sql
-- ==================================================

DELIMITER //

CREATE FUNCTION Get_Total_Cost(p_res INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE base INT DEFAULT 0;
  DECLARE suite_cost INT DEFAULT 0;
  DECLARE activity_cost INT DEFAULT 0;

  SELECT cs.Price_Base INTO base
  FROM Reservation r
  JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
  WHERE r.Reservation_Id = p_res;

  SELECT IFNULL(SUM(s.Price_Per_Day * us.Nights), 0) INTO suite_cost
  FROM User_Suites us
  JOIN Suites s ON us.Suite_Code = s.Suite_Code
  WHERE us.Reservation_Id = p_res;

  SELECT IFNULL(SUM(a.Price), 0) INTO activity_cost
  FROM User_Activities ua
  JOIN Activities a ON ua.Activity_Code = a.Activity_Code
  WHERE ua.Reservation_Id = p_res;

  RETURN base + suite_cost + activity_cost;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/Register_User.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE Register_User(
  IN p_name VARCHAR(200),
  IN p_email VARCHAR(200),
  IN p_mobile CHAR(10),
  IN p_password VARCHAR(255),
  IN p_address VARCHAR(255),
  IN p_dob DATE,
  IN p_gender VARCHAR(50)
)
BEGIN
  INSERT INTO Personal(Full_Name, Email, Mobile_Number, Password, Address, DOB, Gender)
  VALUES (p_name, p_email, p_mobile, p_password, p_address, p_dob, p_gender);
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/Create_Reservation.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE Create_Reservation(
  IN p_user INT,
  IN p_cruise INT,
  IN p_members INT
)
BEGIN
  INSERT INTO Reservation(User_Id, Cruise_Id, Status_Id, Members)
  VALUES (p_user, p_cruise, 1, p_members);
  SELECT LAST_INSERT_ID() AS id;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/Make_Payment.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE Make_Payment(
  IN p_res INT,
  IN p_amount INT
)
BEGIN
  INSERT INTO Payment(Reservation_Id, Amount, Status_Id)
  VALUES (p_res, p_amount, 2);
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetEmail.sql
-- ==================================================

DELIMITER //
CREATE PROCEDURE uspGetEmail (
	IN p_email VARCHAR(200)
)   
BEGIN
	SELECT * FROM Personal WHERE Email = p_email;
END // 
DELIMITER ;

-- ==================================================
-- FILE: Procedures/uspGetUser.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetUser(IN userid INT, IN resid INT)
BEGIN
    SELECT * FROM Reservation WHERE Reservation_Id = resid AND User_Id = userid;
END //

DELIMITER ;



-- ==================================================
-- FILE: Procedures/uspGetCruises.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetCruises()
BEGIN
    SELECT * FROM uvViewCruises;
END //

DELIMITER ;



-- ==================================================
-- FILE: Procedures/uspGetSuites.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetSuites()
BEGIN
    SELECT * FROM Suites;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetActivies.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetActivies()
BEGIN
    SELECT * FROM Activities;
END //

DELIMITER ;



-- ==================================================
-- FILE: Procedures/uspGetMe.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetMe(IN p_regid INT)
BEGIN
    SELECT Registration_Id, Full_Name, Email, Mobile_Number, Address, DOB, Gender
    FROM Personal
    WHERE Registration_Id = p_regid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetTotalCost.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetTotalCost(IN p_resid INT)
BEGIN
    SELECT Get_Total_Cost(p_resid) AS Total_Cost;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetReservationDetails.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetReservationDetails(IN p_resid INT, IN p_userid INT)
BEGIN
    SELECT * FROM uvReservationDetails
    WHERE Reservation_Id = p_resid AND User_Id = p_userid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetPassengers.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetPassengers(IN p_resid INT)
BEGIN
    SELECT * FROM Passengers WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetUserSuites.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetUserSuites(IN p_resid INT)
BEGIN
    SELECT * FROM User_Suites WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspGetUserActivities.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspGetUserActivities(IN p_resid INT)
BEGIN
    SELECT Activity_Code FROM User_Activities WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspUpdateProfile.sql
-- ==================================================

DELIMITER //
DROP PROCEDURE IF EXISTS uspUpdateProfile;

CREATE PROCEDURE uspUpdateProfile(
  IN p_name VARCHAR(200),
  IN p_email VARCHAR(200),
  IN p_mobile CHAR(10),
  IN p_password VARCHAR(255),
  IN p_address VARCHAR(255),
  IN p_dob DATE,
  IN p_gender VARCHAR(50),
  IN p_regid INT
)
BEGIN
	IF p_password = '' THEN
		UPDATE Personal 
		SET Full_Name = p_name, 
		Email = p_email, 
		Mobile_Number = p_mobile,
		Address = p_address,
		DOB = p_dob,
		Gender = p_gender
		WHERE Registration_Id = p_regid;
    ELSE
		UPDATE Personal 
		SET Full_Name = p_name, 
		Email = p_email, 
		Mobile_Number = p_mobile, 
		Password = p_password,
		Address = p_address,
		DOB = p_dob,
		Gender = p_gender
		WHERE Registration_Id = p_regid;
	END IF;
END // 
DELIMITER ;

-- ==================================================
-- FILE: Procedures/uspUpdateReservation.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspUpdateReservation(IN p_cruise INT, IN p_members INT, IN p_resid INT)
BEGIN
    UPDATE Reservation
    SET Cruise_Id = p_cruise, Members = p_members
    WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspDeletePassengers.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspDeletePassengers(IN p_resid INT)
BEGIN
    DELETE FROM Passengers WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspInsertPassenger.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspInsertPassenger(IN p_resid INT, IN p_name VARCHAR(100))
BEGIN
    INSERT INTO Passengers (Reservation_Id, Full_Name) VALUES (p_resid, p_name);
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspDeleteUserSuites.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspDeleteUserSuites(IN p_resid INT)
BEGIN
    DELETE FROM User_Suites WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspInsertUserSuite.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspInsertUserSuite(IN p_resid INT, IN p_suite INT, IN p_nights INT)
BEGIN
    INSERT INTO User_Suites (Reservation_Id, Suite_Code, Nights) VALUES (p_resid, p_suite, p_nights);
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspDeleteUserActivities.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspDeleteUserActivities(IN p_resid INT)
BEGIN
    DELETE FROM User_Activities WHERE Reservation_Id = p_resid;
END //

DELIMITER ;


-- ==================================================
-- FILE: Procedures/uspInsertUserActivity.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uspInsertUserActivity(IN p_resid INT, IN p_actcode INT)
BEGIN
    INSERT INTO User_Activities (Reservation_Id, Activity_Code) VALUES (p_resid, p_actcode);
END //

DELIMITER ;


-- ==================================================
-- FILE: Views/uvMyBookings.sql
-- ==================================================

DELIMITER //

CREATE PROCEDURE uvMyBookings(IN id INT)
BEGIN
    SELECT Reservation_Id, Cruise_Name, Start_Date, End_Date, Members, Status_Name
	FROM Reservation_Summary
	WHERE User_Id = id
	ORDER BY Created_At DESC;
END //

DELIMITER ;



-- ==================================================
-- FILE: Triggers/after_payment.sql
-- ==================================================

DELIMITER //

CREATE TRIGGER after_payment
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
  UPDATE Reservation
  SET Status_Id = 2
  WHERE Reservation_Id = NEW.Reservation_Id;
END //

DELIMITER ;


-- ==================================================
-- FILE: Views/uvViewCruises.sql
-- ==================================================

CREATE VIEW uvViewCruises AS
SELECT cs.Cruise_Id, 
    cm.Cruise_Name, 
    cs.Start_Date, 
    cs.End_Date, 
    cs.Price_Base
	FROM Cruise_Schedule cs
	JOIN Cruise_Master cm ON cs.Cruise_Master_Id = cm.Cruise_Master_Id;

-- ==================================================
-- FILE: Views/uvReservationDetails.sql
-- ==================================================

CREATE VIEW uvReservationDetails AS
SELECT r.Reservation_Id, r.User_Id, r.Cruise_Id, r.Members, r.Status_Id,
       cm.Cruise_Name, cs.Start_Date, cs.End_Date, cs.Price_Base,
       bs.Status_Name
FROM Reservation r
JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
JOIN Cruise_Master cm  ON cs.Cruise_Master_Id = cm.Cruise_Master_Id
JOIN Booking_Status bs ON r.Status_Id = bs.Status_Id;


-- ==================================================
-- FILE: Views/Reservation_Summary.sql
-- ==================================================

CREATE VIEW Reservation_Summary AS
SELECT r.Reservation_Id,
       r.User_Id,
       p.Full_Name,
       cm.Cruise_Name,
       cs.Start_Date,
       cs.End_Date,
       r.Members,
       bs.Status_Name,
       r.Created_At
FROM Reservation r
JOIN Personal p        ON r.User_Id = p.Registration_Id
JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
JOIN Cruise_Master cm  ON cs.Cruise_Master_Id = cm.Cruise_Master_Id
JOIN Booking_Status bs ON r.Status_Id = bs.Status_Id;


-- ==================================================
-- FILE: Seed/seed_data.sql
-- ==================================================

-- =============================================
-- Seed Data - Mariana Cruise Reservation System
-- Run AFTER all tables, functions, procedures,
-- triggers, and views have been created.
-- =============================================

-- 1. Lookup / Status tables
INSERT INTO Booking_Status VALUES (1, 'Pending'), (2, 'Confirmed');
INSERT INTO Payment_Status VALUES (1, 'Pending'), (2, 'Completed');

-- 2. Ports
INSERT INTO Ports (Port_Name, City, Country) VALUES
  ('Port Miami',     'Miami',     'USA'),
  ('Port Barcelona', 'Barcelona', 'Spain'),
  ('Port Dubai',     'Dubai',     'UAE'),
  ('Port Singapore', 'Singapore', 'Singapore'),
  ('Port Sydney',    'Sydney',    'Australia');

-- 3. Cruise_Master
INSERT INTO Cruise_Master (Cruise_Name, Ship_Model, Start_Port_Code, End_Port_Code) VALUES
  ('Atlantic Explorer',  'A1 Luxury',  1, 2),
  ('Desert Pearl Voyage','D2 Premium', 3, 4),
  ('Pacific Odyssey',    'P3 Elite',   4, 5),
  ('European Escape',    'E4 Classic', 2, 1);

-- 4. Cruise_Schedule
INSERT INTO Cruise_Schedule (Cruise_Master_Id, Start_Date, End_Date, Available_Seats, Price_Base) VALUES
  (1, '2026-06-01', '2026-06-10', 100, 30000),
  (2, '2026-07-05', '2026-07-12', 100, 45000),
  (3, '2026-08-15', '2026-08-25', 100, 80000),
  (4, '2026-09-01', '2026-09-10', 100, 35000);

-- 5. Suites
INSERT INTO Suites (Suite_Type, Price_Per_Day, Max_Capacity) VALUES
  ('Interior Suite',   2000,  2),
  ('Ocean View Suite', 4000,  3),
  ('Balcony Suite',    6000,  4),
  ('Royal Suite',      10000, 6);

-- 6. Activities
INSERT INTO Activities (Activity_Name, Price, Max_Capacity) VALUES
  ('Scuba Diving',          3000, 20),
  ('Wine Tasting',          2000, 30),
  ('Casino Night',          1500, 50),
  ('Spa Therapy',           4000, 15),
  ('Sky Diving Simulation', 3500, 10);

-- 7. Personal (users) — passwords are bcrypt hashes of 'Password123'
INSERT INTO Personal (Full_Name, Email, Mobile_Number, Password, Address, DOB, Gender) VALUES
  ('Aarav Sharma',    'aarav.sharma@email.com',    '9876543210', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '123 Marine Drive, Mumbai', '1990-05-15', 'Male'),
  ('Meera Patel',     'meera.patel@email.com',     '9876543211', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '456 MG Road, Bangalore', '1992-08-22', 'Female'),
  ('Rohan Desai',     'rohan.desai@email.com',     '9876543212', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '789 Park Street, Kolkata', '1988-11-30', 'Male'),
  ('Ananya Iyer',     'ananya.iyer@email.com',     '9876543213', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '101 Anna Salai, Chennai', '1995-02-14', 'Female'),
  ('Kabir Mehta',     'kabir.mehta@email.com',      '9876543214', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '202 CG Road, Ahmedabad', '1985-07-07', 'Male'),
  ('Priya Nair',      'priya.nair@email.com',       '9876543215', '$2b$12$WNp77AoR/2Ygb.qR4atxr.mzfexKiJgTioR3/apxFAuSJ0Am5ucDm', '303 MG Marg, Delhi', '1993-09-19', 'Female');

-- 8. Reservations (mix of Pending & Confirmed)
INSERT INTO Reservation (User_Id, Cruise_Id, Status_Id, Members) VALUES
  (1, 1, 2, 2),   -- Aarav  → Atlantic Explorer, Confirmed, 2 members
  (2, 2, 2, 3),   -- Meera  → Desert Pearl Voyage, Confirmed, 3 members
  (3, 3, 1, 1),   -- Rohan  → Pacific Odyssey, Pending, 1 member
  (4, 1, 2, 4),   -- Ananya → Atlantic Explorer, Confirmed, 4 members
  (5, 4, 1, 2),   -- Kabir  → European Escape, Pending, 2 members
  (6, 2, 2, 2);   -- Priya  → Desert Pearl Voyage, Confirmed, 2 members

-- 9. Passengers (additional guests per reservation)
INSERT INTO Passengers (Reservation_Id, Full_Name) VALUES
  (1, 'Aarav Sharma'),
  (1, 'Diya Sharma'),
  (2, 'Meera Patel'),
  (2, 'Vikram Patel'),
  (2, 'Riya Patel'),
  (3, 'Rohan Desai'),
  (4, 'Ananya Iyer'),
  (4, 'Suresh Iyer'),
  (4, 'Lata Iyer'),
  (4, 'Kiran Iyer'),
  (5, 'Kabir Mehta'),
  (5, 'Neha Mehta'),
  (6, 'Priya Nair'),
  (6, 'Arjun Nair');

-- 10. User_Suites (suite selections per reservation)
INSERT INTO User_Suites (Reservation_Id, Suite_Code, Nights) VALUES
  (1, 2, 9),    -- Aarav  → Ocean View Suite, 9 nights
  (2, 3, 7),    -- Meera  → Balcony Suite, 7 nights
  (3, 1, 10),   -- Rohan  → Interior Suite, 10 nights
  (4, 4, 9),    -- Ananya → Royal Suite, 9 nights
  (5, 2, 9),    -- Kabir  → Ocean View Suite, 9 nights
  (6, 3, 7);    -- Priya  → Balcony Suite, 7 nights

-- 11. User_Activities (activity signups per reservation)
INSERT INTO User_Activities (Reservation_Id, Activity_Code) VALUES
  (1, 1),   -- Aarav  → Scuba Diving
  (1, 4),   -- Aarav  → Spa Therapy
  (2, 2),   -- Meera  → Wine Tasting
  (2, 3),   -- Meera  → Casino Night
  (3, 5),   -- Rohan  → Sky Diving Simulation
  (4, 1),   -- Ananya → Scuba Diving
  (4, 2),   -- Ananya → Wine Tasting
  (4, 4),   -- Ananya → Spa Therapy
  (5, 3),   -- Kabir  → Casino Night
  (6, 4),   -- Priya  → Spa Therapy
  (6, 2);   -- Priya  → Wine Tasting

-- 12. Payments (for confirmed reservations)
INSERT INTO Payment (Reservation_Id, Amount, Status_Id) VALUES
  (1, 69000,  2),   -- Aarav  → Completed
  (2, 93500,  2),   -- Meera  → Completed
  (4, 130000, 2),   -- Ananya → Completed
  (6, 90000,  2);   -- Priya  → Completed


