DELIMITER //

CREATE PROCEDURE uspGetUserActivities(IN p_resid INT)
BEGIN
    SELECT Activity_Code FROM User_Activities WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
