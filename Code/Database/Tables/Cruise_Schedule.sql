CREATE TABLE Cruise_Schedule (
  Cruise_Id        INT AUTO_INCREMENT PRIMARY KEY,
  Cruise_Master_Id INT NOT NULL,
  Start_Date       DATE NOT NULL,
  End_Date         DATE NOT NULL,
  Available_Seats  INT DEFAULT 100,
  Price_Base       INT NOT NULL,
  FOREIGN KEY (Cruise_Master_Id) REFERENCES Cruise_Master(Cruise_Master_Id) ON DELETE CASCADE,
  INDEX idx_dates (Start_Date, End_Date)
);
