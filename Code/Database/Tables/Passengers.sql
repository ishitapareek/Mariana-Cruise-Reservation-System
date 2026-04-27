CREATE TABLE Passengers (
  Passenger_Id   INT AUTO_INCREMENT PRIMARY KEY,
  Reservation_Id INT,
  Full_Name      VARCHAR(100),
  FOREIGN KEY (Reservation_Id) REFERENCES Reservation(Reservation_Id) ON DELETE CASCADE
);
