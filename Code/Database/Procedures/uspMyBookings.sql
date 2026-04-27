DELIMITER //

DROP PROCEDURE IF EXISTS uspMyBookings;
CREATE PROCEDURE uspMyBookings(IN id INT)
BEGIN
    SELECT Reservation_Id, Cruise_Name, Start_Date, End_Date, Members, Status_Name
	FROM uvReservationSummary
	WHERE User_Id = id
	ORDER BY Created_At DESC;
END //

DELIMITER ;
