DELIMITER //

CREATE PROCEDURE uspInsertUserActivity(IN p_resid INT, IN p_actcode INT)
BEGIN
    INSERT INTO User_Activities (Reservation_Id, Activity_Code) VALUES (p_resid, p_actcode);
END //

DELIMITER ;
