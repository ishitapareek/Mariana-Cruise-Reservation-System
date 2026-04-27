DELIMITER //

CREATE PROCEDURE uspGetTotalCost(IN p_resid INT)
BEGIN
    SELECT ufGetTotalCost(p_resid) AS Total_Cost;
END //

DELIMITER ;
