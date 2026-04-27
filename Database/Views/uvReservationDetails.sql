CREATE VIEW uvReservationDetails AS
SELECT r.Reservation_Id, r.User_Id, r.Cruise_Id, r.Members, r.Status_Id,
       cm.Cruise_Name, cs.Start_Date, cs.End_Date, cs.Price_Base,
       bs.Status_Name
FROM Reservation r
JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
JOIN Cruise_Master cm  ON cs.Cruise_Master_Id = cm.Cruise_Master_Id
JOIN Booking_Status bs ON r.Status_Id = bs.Status_Id;
