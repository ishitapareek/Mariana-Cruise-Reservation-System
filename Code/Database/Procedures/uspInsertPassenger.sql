DELIMITER //

CREATE PROCEDURE uspInsertPassenger(IN p_resid INT, IN p_name VARCHAR(100))
BEGIN
    INSERT INTO Passengers (Reservation_Id, Full_Name) VALUES (p_resid, p_name);
END //

DELIMITER ;
