DELIMITER //

CREATE PROCEDURE uspGetReservationDetails(IN p_resid INT, IN p_userid INT)
BEGIN
    SELECT * FROM uvReservationDetails
    WHERE Reservation_Id = p_resid AND User_Id = p_userid;
END //

DELIMITER ;
