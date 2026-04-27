CREATE TABLE Cruise_Master (
  Cruise_Master_Id INT AUTO_INCREMENT PRIMARY KEY,
  Cruise_Name      VARCHAR(100) NOT NULL,
  Ship_Model       VARCHAR(45),
  Start_Port_Code  INT,
  End_Port_Code    INT,
  FOREIGN KEY (Start_Port_Code) REFERENCES Ports(Port_Code) ON DELETE SET NULL,
  FOREIGN KEY (End_Port_Code)   REFERENCES Ports(Port_Code) ON DELETE SET NULL
);
