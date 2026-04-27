DELIMITER //

CREATE PROCEDURE uspDeletePassengers(IN p_resid INT)
BEGIN
    DELETE FROM Passengers WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
