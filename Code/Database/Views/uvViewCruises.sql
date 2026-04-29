CREATE VIEW uvViewCruises AS
SELECT Cruise_Id, 
    Cruise_Name, 
    Start_Date, 
    End_Date, 
    Price_Base
	FROM Cruise_Schedule;