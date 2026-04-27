CREATE VIEW uvViewCruises AS
SELECT cs.Cruise_Id, 
    cm.Cruise_Name, 
    cs.Start_Date, 
    cs.End_Date, 
    cs.Price_Base
	FROM Cruise_Schedule cs
	JOIN Cruise_Master cm ON cs.Cruise_Master_Id = cm.Cruise_Master_Id;