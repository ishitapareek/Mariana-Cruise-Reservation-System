from flask import Flask, request, jsonify, render_template, session
from flask_cors import CORS
import bcrypt
from db import get_db

app = Flask(__name__)
app.secret_key = "supersecretkey"
CORS(app, supports_credentials=True)


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/api/register", methods=["POST"])
def register():
    data = request.json
    name = data.get("name")
    email = data.get("email")
    mobile = data.get("mobile")
    password = data.get("password")

    if not name or not email or not password:
        return jsonify({"error": "Missing fields"}), 400

    hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
    db = get_db()
    cursor = db.cursor()

    try:
        cursor.execute("CALL Register_User(%s, %s, %s, %s)", (name, email, mobile, hashed.decode()))
        db.commit()
        return jsonify({"message": "User registered successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("SELECT * FROM Personal WHERE Email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"error": "User not found"}), 404
        if not user["Password"]:
            return jsonify({"error": "Password missing in DB"}), 400

        if bcrypt.checkpw(password.encode(), user["Password"].encode()):
            session["user_id"] = user["Registration_Id"]
            return jsonify({
                "message": "Login success",
                "user": {
                    "Full_Name": user["Full_Name"],
                    "Email": user["Email"],
                    "Registration_Id": user["Registration_Id"]
                }
            })

        return jsonify({"error": "Invalid credentials"}), 401
    finally:
        cursor.close()
        db.close()


@app.route("/api/cruises", methods=["GET"])
def get_cruises():
    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT cs.Cruise_Id, cm.Cruise_Name, cs.Start_Date, cs.End_Date, cs.Price_Base
            FROM Cruise_Schedule cs
            JOIN Cruise_Master cm ON cs.Cruise_Master_Id = cm.Cruise_Master_Id
        """)
        cruises = cursor.fetchall()

        for c in cruises:
            if c.get("Start_Date"):
                c["Start_Date"] = str(c["Start_Date"])
            if c.get("End_Date"):
                c["End_Date"] = str(c["End_Date"])

        return jsonify(cruises)
    finally:
        cursor.close()
        db.close()


@app.route("/api/book", methods=["POST"])
def book():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    cruise_id = data.get("cruise_id")
    members = data.get("members")

    if not cruise_id or not members:
        return jsonify({"error": "Missing cruise_id or members"}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("CALL Create_Reservation(%s, %s, %s)", (session["user_id"], cruise_id, members))
        db.commit()

        cursor.execute("SELECT LAST_INSERT_ID() AS id")
        result = cursor.fetchone()
        return jsonify({"message": "Booking successful", "reservation_id": result["id"] if result else None})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/my-bookings", methods=["GET"])
def my_bookings():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT Reservation_Id, Cruise_Name, Start_Date, End_Date, Members, Status_Name
            FROM Reservation_Summary
            WHERE User_Id = %s
            ORDER BY Created_At DESC
        """, (session["user_id"],))
        bookings = cursor.fetchall()

        for b in bookings:
            if b.get("Start_Date"):
                b["Start_Date"] = str(b["Start_Date"])
            if b.get("End_Date"):
                b["End_Date"] = str(b["End_Date"])

        return jsonify(bookings)
    finally:
        cursor.close()
        db.close()


@app.route("/api/pay", methods=["POST"])
def pay():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    reservation_id = data.get("reservation_id")
    amount = data.get("amount")

    if not reservation_id or not amount:
        return jsonify({"error": "Missing reservation_id or amount"}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT * FROM Reservation WHERE Reservation_Id = %s AND User_Id = %s",
            (reservation_id, session["user_id"])
        )
        if not cursor.fetchone():
            return jsonify({"error": "Reservation not found"}), 404

        # Trigger after_payment auto-updates status to Confirmed
        cursor.execute("CALL Make_Payment(%s, %s)", (reservation_id, amount))
        db.commit()
        return jsonify({"message": "Payment successful"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/cost/<int:res_id>", methods=["GET"])
def get_cost(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT Reservation_Id FROM Reservation WHERE Reservation_Id = %s AND User_Id = %s",
            (res_id, session["user_id"])
        )
        if not cursor.fetchone():
            return jsonify({"error": "Reservation not found"}), 404

        cursor.execute("SELECT Get_Total_Cost(%s) AS Total_Cost", (res_id,))
        result = cursor.fetchone()
        return jsonify({"total": result["Total_Cost"] if result else 0})
    finally:
        cursor.close()
        db.close()


@app.route("/api/suites", methods=["GET"])
def get_suites():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM Suites")
        return jsonify(cursor.fetchall())
    finally:
        cursor.close()
        db.close()


@app.route("/api/activities", methods=["GET"])
def get_activities():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM Activities")
        return jsonify(cursor.fetchall())
    finally:
        cursor.close()
        db.close()


@app.route("/api/reservation/<int:res_id>", methods=["GET"])
def get_reservation(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT r.Reservation_Id, r.Cruise_Id, r.Members, r.Status_Id,
                   cm.Cruise_Name, cs.Start_Date, cs.End_Date, cs.Price_Base,
                   bs.Status_Name
            FROM Reservation r
            JOIN Cruise_Schedule cs ON r.Cruise_Id = cs.Cruise_Id
            JOIN Cruise_Master cm  ON cs.Cruise_Master_Id = cm.Cruise_Master_Id
            JOIN Booking_Status bs ON r.Status_Id = bs.Status_Id
            WHERE r.Reservation_Id = %s AND r.User_Id = %s
        """, (res_id, session["user_id"]))
        res = cursor.fetchone()

        if not res:
            return jsonify({"error": "Reservation not found"}), 404

        if res.get("Start_Date"):
            res["Start_Date"] = str(res["Start_Date"])
        if res.get("End_Date"):
            res["End_Date"] = str(res["End_Date"])

        cursor.execute("SELECT * FROM Passengers WHERE Reservation_Id = %s", (res_id,))
        res["passengers"] = cursor.fetchall()

        cursor.execute("SELECT * FROM User_Suites WHERE Reservation_Id = %s", (res_id,))
        res["suites"] = cursor.fetchall()

        cursor.execute("SELECT Activity_Code FROM User_Activities WHERE Reservation_Id = %s", (res_id,))
        res["activities"] = [r["Activity_Code"] for r in cursor.fetchall()]

        cursor.execute("SELECT Get_Total_Cost(%s) AS Total_Cost", (res_id,))
        cost_result = cursor.fetchone()
        res["Total_Cost"] = cost_result["Total_Cost"] if cost_result else 0

        return jsonify(res)
    finally:
        cursor.close()
        db.close()


@app.route("/api/reservation/<int:res_id>", methods=["PUT"])
def update_reservation(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT * FROM Reservation WHERE Reservation_Id = %s AND User_Id = %s",
            (res_id, session["user_id"])
        )
        existing = cursor.fetchone()
        if not existing:
            return jsonify({"error": "Reservation not found"}), 404
        if existing["Status_Id"] != 1:
            return jsonify({"error": "Only pending reservations can be edited"}), 400

        data = request.json
        cruise_id = data.get("cruise_id", existing["Cruise_Id"])
        members = data.get("members", existing["Members"])
        passengers = data.get("passengers", [])
        suite_code = data.get("suite_code")
        suite_nights = data.get("suite_nights", 1)
        activities = data.get("activities", [])

        cursor.execute(
            "UPDATE Reservation SET Cruise_Id = %s, Members = %s WHERE Reservation_Id = %s",
            (cruise_id, members, res_id)
        )

        cursor.execute("DELETE FROM Passengers WHERE Reservation_Id = %s", (res_id,))
        for p in passengers:
            name = p.get("name", "").strip()
            if name:
                cursor.execute(
                    "INSERT INTO Passengers (Reservation_Id, Full_Name) VALUES (%s, %s)",
                    (res_id, name)
                )

        cursor.execute("DELETE FROM User_Suites WHERE Reservation_Id = %s", (res_id,))
        if suite_code:
            cursor.execute(
                "INSERT INTO User_Suites (Reservation_Id, Suite_Code, Nights) VALUES (%s, %s, %s)",
                (res_id, suite_code, suite_nights)
            )

        cursor.execute("DELETE FROM User_Activities WHERE Reservation_Id = %s", (res_id,))
        for act_code in activities:
            cursor.execute(
                "INSERT INTO User_Activities (Reservation_Id, Activity_Code) VALUES (%s, %s)",
                (res_id, act_code)
            )

        db.commit()
        return jsonify({"message": "Reservation updated successfully"})
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/logout")
def logout():
    session.clear()
    return jsonify({"message": "Logged out"})


@app.route("/api/me")
def get_me():
    if "user_id" not in session:
        return jsonify({"user": None})

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT Registration_Id, Full_Name, Email, Mobile_Number FROM Personal WHERE Registration_Id = %s",
            (session["user_id"],)
        )
        user = cursor.fetchone()
        return jsonify({"user": user})
    finally:
        cursor.close()
        db.close()


@app.route("/api/profile", methods=["PUT"])
def update_profile():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    name = data.get("name", "").strip()
    email = data.get("email", "").strip()
    mobile = data.get("mobile", "").strip()
    new_password = data.get("password", "").strip()

    if not name or not email:
        return jsonify({"error": "Name and email are required"}), 400

    db = get_db()
    cursor = db.cursor()

    try:
        if new_password:
            hashed = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt())
            cursor.execute(
                "UPDATE Personal SET Full_Name=%s, Email=%s, Mobile_Number=%s, Password=%s WHERE Registration_Id=%s",
                (name, email, mobile, hashed.decode(), session["user_id"])
            )
        else:
            cursor.execute(
                "UPDATE Personal SET Full_Name=%s, Email=%s, Mobile_Number=%s WHERE Registration_Id=%s",
                (name, email, mobile, session["user_id"])
            )

        db.commit()
        return jsonify({"message": "Profile updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


if __name__ == "__main__":
    app.run(debug=True)