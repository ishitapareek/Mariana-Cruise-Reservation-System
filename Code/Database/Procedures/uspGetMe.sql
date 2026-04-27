DELIMITER //

CREATE PROCEDURE uspGetMe(IN p_regid INT)
BEGIN
    SELECT Registration_Id, Full_Name, Email, Mobile_Number, Address, DOB, Gender
    FROM Personal
    WHERE Registration_Id = p_regid;
END //

DELIMITER ;
