import mysql.connector

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="admin",
        database="Cruise_Reservation_System"
    )