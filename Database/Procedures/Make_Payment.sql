DELIMITER //

CREATE PROCEDURE Make_Payment(
  IN p_res INT,
  IN p_amount INT
)
BEGIN
  INSERT INTO Payment(Reservation_Id, Amount, Status_Id)
  VALUES (p_res, p_amount, 2);
END //

DELIMITER ;
