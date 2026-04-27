DELIMITER //

CREATE PROCEDURE uspGetUserSuites(IN p_resid INT)
BEGIN
    SELECT * FROM User_Suites WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
