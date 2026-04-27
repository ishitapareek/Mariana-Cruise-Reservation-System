DELIMITER //

CREATE PROCEDURE uspGetPassengers(IN p_resid INT)
BEGIN
    SELECT * FROM Passengers WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
