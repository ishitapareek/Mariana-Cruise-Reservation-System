CREATE TABLE Suites (
  Suite_Code    INT AUTO_INCREMENT PRIMARY KEY,
  Suite_Type    VARCHAR(50),
  Price_Per_Day INT NOT NULL,
  Max_Capacity  INT NOT NULL
);
