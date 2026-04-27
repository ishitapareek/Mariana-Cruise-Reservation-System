DELIMITER //
DROP PROCEDURE IF EXISTS uspUpdateProfile;

CREATE PROCEDURE uspUpdateProfile(
  IN p_name VARCHAR(200),
  IN p_email VARCHAR(200),
  IN p_mobile CHAR(10),
  IN p_password VARCHAR(255),
  IN p_address VARCHAR(255),
  IN p_dob DATE,
  IN p_gender VARCHAR(50),
  IN p_regid INT
)
BEGIN
	IF p_password = '' THEN
		UPDATE Personal 
		SET Full_Name = p_name, 
		Email = p_email, 
		Mobile_Number = p_mobile,
		Address = p_address,
		DOB = p_dob,
		Gender = p_gender
		WHERE Registration_Id = p_regid;
    ELSE
		UPDATE Personal 
		SET Full_Name = p_name, 
		Email = p_email, 
		Mobile_Number = p_mobile, 
		Password = p_password,
		Address = p_address,
		DOB = p_dob,
		Gender = p_gender
		WHERE Registration_Id = p_regid;
	END IF;
END // 
DELIMITER ;