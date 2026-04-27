DELIMITER //

CREATE PROCEDURE uspCreateReservation(
  IN p_user INT,
  IN p_cruise INT,
  IN p_members INT
)
BEGIN
  INSERT INTO Reservation(User_Id, Cruise_Id, Status_Id, Members)
  VALUES (p_user, p_cruise, 1, p_members);
  SELECT LAST_INSERT_ID() AS id;
END //

DELIMITER ;
