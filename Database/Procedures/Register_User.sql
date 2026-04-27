DELIMITER //

CREATE PROCEDURE Register_User(
  IN p_name VARCHAR(200),
  IN p_email VARCHAR(200),
  IN p_mobile CHAR(10),
  IN p_password VARCHAR(255),
  IN p_address VARCHAR(255),
  IN p_dob DATE,
  IN p_gender VARCHAR(50)
)
BEGIN
  INSERT INTO Personal(Full_Name, Email, Mobile_Number, Password, Address, DOB, Gender)
  VALUES (p_name, p_email, p_mobile, p_password, p_address, p_dob, p_gender);
END //

DELIMITER ;
