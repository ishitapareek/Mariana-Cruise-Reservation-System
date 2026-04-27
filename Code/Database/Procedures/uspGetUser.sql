DELIMITER //

CREATE PROCEDURE uspGetUser(IN userid INT, IN resid INT)
BEGIN
    SELECT * FROM Reservation WHERE Reservation_Id = resid AND User_Id = userid;
END //

DELIMITER ;

