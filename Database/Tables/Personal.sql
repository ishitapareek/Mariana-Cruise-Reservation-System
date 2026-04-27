CREATE TABLE Personal (
  Registration_Id INT AUTO_INCREMENT PRIMARY KEY,
  Full_Name       VARCHAR(200) NOT NULL,
  Email           VARCHAR(200) NOT NULL UNIQUE,
  Mobile_Number   CHAR(10) UNIQUE,
  Password        VARCHAR(255) NOT NULL,
  Address         VARCHAR(255),
  DOB             DATE,
  Gender          VARCHAR(50),
  Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (Email)
);
