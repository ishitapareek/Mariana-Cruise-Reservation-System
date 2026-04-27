DELIMITER //

CREATE PROCEDURE uvMyBookings(IN id INT)
BEGIN
    SELECT Reservation_Id, Cruise_Name, Start_Date, End_Date, Members, Status_Name
	FROM Reservation_Summary
	WHERE User_Id = id
	ORDER BY Created_At DESC;
END //

DELIMITER ;

