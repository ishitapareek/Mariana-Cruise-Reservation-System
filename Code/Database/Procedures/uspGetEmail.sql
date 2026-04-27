DELIMITER //
CREATE PROCEDURE uspGetEmail (
	IN p_email VARCHAR(200)
)   
BEGIN
	SELECT * FROM Personal WHERE Email = p_email;
END // 
DELIMITER ;