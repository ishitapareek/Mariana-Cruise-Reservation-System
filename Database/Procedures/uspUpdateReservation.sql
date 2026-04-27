DELIMITER //

CREATE PROCEDURE uspUpdateReservation(IN p_cruise INT, IN p_members INT, IN p_resid INT)
BEGIN
    UPDATE Reservation
    SET Cruise_Id = p_cruise, Members = p_members
    WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
