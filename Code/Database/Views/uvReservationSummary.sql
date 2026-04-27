CREATE OR REPLACE VIEW uvReservationSummary AS
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
