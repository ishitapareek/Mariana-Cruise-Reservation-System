CREATE TABLE User_Activities (
  Reservation_Id INT,
  Activity_Code  INT,
  PRIMARY KEY (Reservation_Id, Activity_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Activity_Code)  REFERENCES Activities(Activity_Code)
);
