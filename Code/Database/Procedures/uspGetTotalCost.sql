DELIMITER //

CREATE PROCEDURE uspGetTotalCost(IN p_resid INT)
BEGIN
    SELECT Get_Total_Cost(p_resid) AS Total_Cost;
END //

DELIMITER ;
