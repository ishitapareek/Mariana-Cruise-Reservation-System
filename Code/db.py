import mysql.connector

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="*****",
        database="Cruise_Reservation_System"
    )

def call_proc(proc_name, params=None, fetch="all"):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.callproc(proc_name, params or ())
        for result in cursor.stored_results():
            if fetch == "one":
                return result.fetchone()
            return result.fetchall()
        return None if fetch == "one" else []
    finally:
        cursor.close()
        db.close()

def execute_proc(proc_name, params=None):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.callproc(proc_name, params or ())
        row = None
        for result in cursor.stored_results():
            row = result.fetchone()
        db.commit()
        return row
    finally:
        cursor.close()
        db.close()
