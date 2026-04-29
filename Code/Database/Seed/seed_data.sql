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