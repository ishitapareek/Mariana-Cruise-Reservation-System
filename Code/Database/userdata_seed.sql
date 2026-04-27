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