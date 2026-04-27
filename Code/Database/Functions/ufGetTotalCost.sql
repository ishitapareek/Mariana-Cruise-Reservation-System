DELIMITER //

CREATE FUNCTION ufGetTotalCost(p_res INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE base INT DEFAULT 0;
  DECLARE suite_cost INT DEFAULT 0;
  DECLARE activity_cost INT DEFAULT 0;

  SELECT cs.Price_Base INTO base
  FROM Reservation r
  JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
  WHERE r.Reservation_Id = p_res;

  SELECT IFNULL(SUM(s.Price_Per_Day * us.Nights), 0) INTO suite_cost
  FROM User_Suites us
  JOIN Suites s ON us.Suite_Code = s.Suite_Code
  WHERE us.Reservation_Id = p_res;

  SELECT IFNULL(SUM(a.Price), 0) INTO activity_cost
  FROM User_Activities ua
  JOIN Activities a ON ua.Activity_Code = a.Activity_Code
  WHERE ua.Reservation_Id = p_res;

  RETURN base + suite_cost + activity_cost;
END //

DELIMITER ;
