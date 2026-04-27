DELIMITER //

CREATE PROCEDURE uspDeleteUserActivities(IN p_resid INT)
BEGIN
    DELETE FROM User_Activities WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
