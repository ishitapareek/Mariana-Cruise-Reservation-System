DELIMITER //

CREATE PROCEDURE uspInsertUserSuite(IN p_resid INT, IN p_suite INT, IN p_nights INT)
BEGIN
    INSERT INTO User_Suites (Reservation_Id, Suite_Code, Nights) VALUES (p_resid, p_suite, p_nights);
END //

DELIMITER ;
