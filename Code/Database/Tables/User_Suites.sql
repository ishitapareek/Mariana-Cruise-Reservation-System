CREATE TABLE User_Suites (
  Reservation_Id INT,
  Suite_Code     INT,
  Nights         INT DEFAULT 1,
  PRIMARY KEY (Reservation_Id, Suite_Code),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE,
  FOREIGN KEY (Suite_Code)     REFERENCES Suites(Suite_Code)
);
