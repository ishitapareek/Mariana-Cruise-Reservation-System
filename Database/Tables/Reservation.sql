CREATE TABLE Reservation (
  Reservation_Id INT AUTO_INCREMENT PRIMARY KEY,
  User_Id        INT NOT NULL,
  Cruise_Id      INT NOT NULL,
  Status_Id      INT NOT NULL,
  Members        INT NOT NULL,
  Created_At     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (User_Id)   REFERENCES Personal(Registration_Id) ON DELETE CASCADE,
  FOREIGN KEY (Cruise_Id) REFERENCES Cruise_Schedule(Cruise_Id) ON DELETE CASCADE,
  FOREIGN KEY (Status_Id) REFERENCES Booking_Status(Status_Id),
  INDEX idx_user (User_Id),
  INDEX idx_cruise (Cruise_Id)
);
