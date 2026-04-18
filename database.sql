-- Mariana Cruise Reservation System

DROP DATABASE IF EXISTS Cruise_Reservation_System;
CREATE DATABASE Cruise_Reservation_System CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE Cruise_Reservation_System;

-- Users
CREATE TABLE Personal (
  Registration_Id INT AUTO_INCREMENT PRIMARY KEY,
  Full_Name       VARCHAR(200) NOT NULL,
  Email           VARCHAR(200) NOT NULL UNIQUE,
  Mobile_Number   CHAR(10) UNIQUE,
  Password        VARCHAR(255) NOT NULL,
  Role            ENUM('user','admin') DEFAULT 'user',
  Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (Email)
);

-- Ports
CREATE TABLE Ports (
  Port_Code INT AUTO_INCREMENT PRIMARY KEY,
  Port_Name VARCHAR(100) NOT NULL,
  City      VARCHAR(45),
  Country   VARCHAR(45)
);

-- Cruise Master (static info)
CREATE TABLE Cruise_Master (
  Cruise_Master_Id INT AUTO_INCREMENT PRIMARY KEY,
  Cruise_Name      VARCHAR(100) NOT NULL,
  Ship_Model       VARCHAR(45),
  Start_Port_Code  INT,
  End_Port_Code    INT,
  FOREIGN KEY (Start_Port_Code) REFERENCES Ports(Port_Code) ON DELETE SET NULL,
  FOREIGN KEY (End_Port_Code)   REFERENCES Ports(Port_Code) ON DELETE SET NULL
);

-- Cruise Schedule (dates & pricing)
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

-- Suites
CREATE TABLE Suites (
  Suite_Code    INT AUTO_INCREMENT PRIMARY KEY,
  Suite_Type    VARCHAR(50),
  Price_Per_Day INT NOT NULL,
  Max_Capacity  INT NOT NULL
);

-- Activities
CREATE TABLE Activities (
  Activity_Code INT AUTO_INCREMENT PRIMARY KEY,
  Activity_Name VARCHAR(50),
  Price         INT NOT NULL,
  Max_Capacity  INT
);

-- Status lookup tables
CREATE TABLE Booking_Status (
  Status_Id   INT PRIMARY KEY,
  Status_Name VARCHAR(50) UNIQUE
);

CREATE TABLE Payment_Status (
  Status_Id   INT PRIMARY KEY,
  Status_Name VARCHAR(50) UNIQUE
);

-- Reservations
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

-- Passengers
CREATE TABLE Passengers (
  Passenger_Id   INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Full_Name      VARCHAR(100),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE
);

-- User Suites
CREATE TABLE User_Suites (
  Reservation_Id INT,
  Suite_Code     INT,
  Nights         INT DEFAULT 1,
  PRIMARY KEY (Reservation_Id, Suite_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Suite_Code)     REFERENCES Suites(Suite_Code)
);

-- User Activities
CREATE TABLE User_Activities (
  Reservation_Id INT,
  Activity_Code  INT,
  PRIMARY KEY (Reservation_Id, Activity_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Activity_Code)  REFERENCES Activities(Activity_Code)
);

-- Payment
CREATE TABLE Payment (
  Transaction_Id INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Amount         INT,
  Status_Id      INT,
  Created_At     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id),
  FOREIGN KEY (Status_Id)      REFERENCES Payment_Status(Status_Id)
);

-- Stored Procedures
DELIMITER //

CREATE PROCEDURE Register_User(
  IN p_name VARCHAR(200),
  IN p_email VARCHAR(200),
  IN p_mobile CHAR(10),
  IN p_password VARCHAR(255)
)
BEGIN
  INSERT INTO Personal(Full_Name, Email, Mobile_Number, Password)
  VALUES (p_name, p_email, p_mobile, p_password);
END //

CREATE PROCEDURE Create_Reservation(
  IN p_user INT,
  IN p_cruise INT,
  IN p_members INT
)
BEGIN
  INSERT INTO Reservation(User_Id, Cruise_Id, Status_Id, Members)
  VALUES (p_user, p_cruise, 1, p_members);
END //

CREATE PROCEDURE Make_Payment(
  IN p_res INT,
  IN p_amount INT
)
BEGIN
  INSERT INTO Payment(Reservation_Id, Amount, Status_Id)
  VALUES (p_res, p_amount, 2);
END //

-- Function to calculate total reservation cost
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

-- Trigger: auto-confirm reservation on payment
CREATE TRIGGER after_payment
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
  UPDATE Reservation
  SET Status_Id = 2
  WHERE Reservation_Id = NEW.Reservation_Id;
END //

DELIMITER ;

-- View for reservation summaries
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

-- Seed: Status values
INSERT INTO Booking_Status VALUES (1, 'Pending'), (2, 'Confirmed');
INSERT INTO Payment_Status VALUES (1, 'Pending'), (2, 'Completed');

-- Seed: Ports
INSERT INTO Ports (Port_Name, City, Country) VALUES
  ('Port Miami',     'Miami',     'USA'),
  ('Port Barcelona', 'Barcelona', 'Spain'),
  ('Port Dubai',     'Dubai',     'UAE'),
  ('Port Singapore', 'Singapore', 'Singapore'),
  ('Port Sydney',    'Sydney',    'Australia');

-- Seed: Cruise Master
INSERT INTO Cruise_Master (Cruise_Name, Ship_Model, Start_Port_Code, End_Port_Code) VALUES
  ('Atlantic Explorer',  'A1 Luxury',  1, 2),
  ('Desert Pearl Voyage','D2 Premium', 3, 4),
  ('Pacific Odyssey',    'P3 Elite',   4, 5),
  ('European Escape',    'E4 Classic', 2, 1);

-- Seed: Cruise Schedule
INSERT INTO Cruise_Schedule (Cruise_Master_Id, Start_Date, End_Date, Available_Seats, Price_Base) VALUES
  (1, '2026-06-01', '2026-06-10', 100, 30000),
  (2, '2026-07-05', '2026-07-12', 100, 45000),
  (3, '2026-08-15', '2026-08-25', 100, 80000),
  (4, '2026-09-01', '2026-09-10', 100, 35000);

-- Seed: Suites
INSERT INTO Suites (Suite_Type, Price_Per_Day, Max_Capacity) VALUES
  ('Interior Suite',   2000,  2),
  ('Ocean View Suite', 4000,  3),
  ('Balcony Suite',    6000,  4),
  ('Royal Suite',      10000, 6);

-- Seed: Activities
INSERT INTO Activities (Activity_Name, Price, Max_Capacity) VALUES
  ('Scuba Diving',          3000, 20),
  ('Wine Tasting',          2000, 30),
  ('Casino Night',          1500, 50),
  ('Spa Therapy',           4000, 15),
  ('Sky Diving Simulation', 3500, 10);