DELIMITER //

CREATE PROCEDURE uspGetCruises()
BEGIN
    SELECT Cruise_Id, 
    cmCruise_Name, 
    Start_Date, 
    End_Date, 
    Price_Base
	FROM Cruise_Schedule;
END //

DELIMITER ;

