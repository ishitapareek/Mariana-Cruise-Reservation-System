DELIMITER //

CREATE PROCEDURE uspDeleteUserSuites(IN p_resid INT)
BEGIN
    DELETE FROM User_Suites WHERE Reservation_Id = p_resid;
END //

DELIMITER ;
