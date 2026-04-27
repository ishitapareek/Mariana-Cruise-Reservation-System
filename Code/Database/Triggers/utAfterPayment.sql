DELIMITER //

CREATE TRIGGER utAfterPayment
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
  UPDATE Reservation
  SET Status_Id = 2
  WHERE Reservation_Id = NEW.Reservation_Id;
END //

DELIMITER ;
