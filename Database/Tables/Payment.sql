CREATE TABLE Payment (
  Transaction_Id INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Amount         INT,
  Status_Id      INT,
  Created_At     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id),
  FOREIGN KEY (Status_Id)      REFERENCES Payment_Status(Status_Id)
);
