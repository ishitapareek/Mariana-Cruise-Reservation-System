from flask import Flask, request, jsonify, render_template, session
from flask_cors import CORS
import bcrypt
from db import get_db

app = Flask(__name__)
app.secret_key = "supersecretkey"
CORS(app, supports_credentials = True)

@app.route("/")
def home(): 
    return render_template("index.html")


@app.route("/api/register", methods = ["POST"])
def register():
    data = request.json
    name = data.get("name")
    email = data.get("email")
    mobile = data.get("mobile")
    password = data.get("password")

    address = data.get("address", None)
    dob = data.get("dob", None)
    gender = data.get("gender", None)

    if not name or not email or not password:
        return jsonify({"error": "Missing fields"}), 400

    hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
    db = get_db()
    cursor = db.cursor()

    params = (name, email, mobile, hashed.decode(), address, dob, gender)

    try:
        cursor.callproc("Register_User", params)
        db.commit()
        return jsonify({"message": "User registered successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/login", methods = ["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    db = get_db()
    cursor = db.cursor(dictionary = True)

    params = (email,)

    try:
        cursor.callproc('uspGetEmail', params)
        user = ''

        for result in cursor.stored_results():
            user = result.fetchone()

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


@app.route("/api/cruises", methods = ["GET"])
def get_cruises():
    db = get_db()
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetCruises')

        cruises = []
        for result in cursor.stored_results():
            cruises = result.fetchall()

        for c in cruises:
            if c.get("Start_Date"):
                c["Start_Date"] = str(c["Start_Date"])
            if c.get("End_Date"):
                c["End_Date"] = str(c["End_Date"])

        return jsonify(cruises)
    finally:
        cursor.close()
        db.close()


@app.route("/api/book", methods = ["POST"])
def book():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    cruise_id = data.get("cruise_id")
    members = data.get("members")

    if not cruise_id or not members:
        return jsonify({"error": "Missing cruise_id or members"}), 400

    db = get_db()
    cursor = db.cursor(dictionary = True)

    params = (session["user_id"], cruise_id, members)

    try:
        cursor.callproc("Create_Reservation", params)

        result = ''
        for r in cursor.stored_results():
            result = r.fetchone()

        db.commit()
        return jsonify({"message": "Booking successful", "reservation_id": result["id"] if result else None})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/my-bookings", methods = ["GET"])
def my_bookings():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uvMyBookings', (session["user_id"],))

        bookings = ''
        for result in cursor.stored_results():
            bookings = result.fetchall()

        for b in bookings:
            if b.get("Start_Date"):
                b["Start_Date"] = str(b["Start_Date"])  
            if b.get("End_Date"):
                b["End_Date"] = str(b["End_Date"])

        return jsonify(bookings)
    finally:
        cursor.close()
        db.close()


@app.route("/api/pay", methods = ["POST"])
def pay():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    reservation_id = data.get("reservation_id")
    amount = data.get("amount")

    if not reservation_id or not amount:
        return jsonify({"error": "Missing reservation_id or amount"}), 400

    db = get_db()
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetUser', (session["user_id"], reservation_id))

        reservation = ''
        for result in cursor.stored_results():
            reservation = result.fetchone()

        if not reservation:
            return jsonify({"error": "Reservation not found"}), 404

        # Trigger after_payment auto-updates status to Confirmed
        cursor.callproc('Make_Payment', (reservation_id, amount))
        db.commit()
        return jsonify({"message": "Payment successful"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/cost/<int:res_id>", methods = ["GET"])
def get_cost(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetUser', (session["user_id"], res_id))

        reservation = ''
        for result in cursor.stored_results():
            reservation = result.fetchone()

        if not reservation:
            return jsonify({"error": "Reservation not found"}), 404

        cursor.callproc('uspGetTotalCost', (res_id,))

        cost = ''
        for result in cursor.stored_results():
            cost = result.fetchone()

        return jsonify({"total": cost["Total_Cost"] if cost else 0})
    finally:
        cursor.close()
        db.close()


@app.route("/api/suites", methods = ["GET"])
def get_suites():
    db = get_db()
    cursor = db.cursor(dictionary = True)
    try:
        cursor.callproc('uspGetSuites')

        suites = ''
        for result in cursor.stored_results():
            suites = result.fetchall()
            
        return jsonify(suites)
    finally:
        cursor.close()
        db.close()


@app.route("/api/activities", methods = ["GET"])
def get_activities():
    db = get_db()
    cursor = db.cursor(dictionary = True)
    try:
        cursor.callproc('uspGetActivies')

        activities = ''
        for result in cursor.stored_results():
            activities = result.fetchall()

        return jsonify(activities)
    finally:
        cursor.close()
        db.close()


@app.route("/api/reservation/<int:res_id>", methods=["GET"])
def get_reservation(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    db = get_db()
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetReservationDetails', (res_id, session["user_id"]))

        res = ''
        for result in cursor.stored_results():
            res = result.fetchone()

        if not res:
            return jsonify({"error": "Reservation not found"}), 404

        if res.get("Start_Date"):
            res["Start_Date"] = str(res["Start_Date"])
        if res.get("End_Date"):
            res["End_Date"] = str(res["End_Date"])

        cursor.callproc('uspGetPassengers', (res_id,))
        for result in cursor.stored_results():
            res["passengers"] = result.fetchall()

        cursor.callproc('uspGetUserSuites', (res_id,))
        for result in cursor.stored_results():
            res["suites"] = result.fetchall()

        cursor.callproc('uspGetUserActivities', (res_id,))
        for result in cursor.stored_results():
            res["activities"] = [r["Activity_Code"] for r in result.fetchall()]

        cursor.callproc('uspGetTotalCost', (res_id,))
        for result in cursor.stored_results():
            cost_result = result.fetchone()
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
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetUser', (session["user_id"], res_id))

        existing = ''
        for result in cursor.stored_results():
            existing = result.fetchone()

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

        cursor.callproc('uspUpdateReservation', (cruise_id, members, res_id))

        cursor.callproc('uspDeletePassengers', (res_id,))
        for p in passengers:
            name = p.get("name", "").strip()
            if name:
                cursor.callproc('uspInsertPassenger', (res_id, name))

        cursor.callproc('uspDeleteUserSuites', (res_id,))
        if suite_code:
            cursor.callproc('uspInsertUserSuite', (res_id, suite_code, suite_nights))

        cursor.callproc('uspDeleteUserActivities', (res_id,))
        for act_code in activities:
            cursor.callproc('uspInsertUserActivity', (res_id, act_code))

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
    cursor = db.cursor(dictionary = True)

    try:
        cursor.callproc('uspGetMe', (session["user_id"],))

        user = ''
        for result in cursor.stored_results():
            user = result.fetchone()
            
        if user and user.get("DOB"):
            user["DOB"] = str(user["DOB"])

        return jsonify({"user": user})
    finally:
        cursor.close()
        db.close()


@app.route("/api/profile", methods = ["PUT"])
def update_profile():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    name = data.get("name", "").strip()
    email = data.get("email", "").strip()
    mobile = data.get("mobile", "").strip()
    new_password = data.get("password", "").strip()
    address = data.get("address", "").strip()
    dob = data.get("dob", "").strip()
    gender = data.get("gender", "").strip()

    if not dob:
        dob = None

    if not name or not email:
        return jsonify({"error": "Name and email are required"}), 400

    db = get_db()
    cursor = db.cursor()

    hashed = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt()) if new_password else ""

    params = (name, email, mobile, hashed.decode() if isinstance(hashed, bytes) else hashed, address, dob, gender, session["user_id"])
    
    try:
        cursor.callproc('uspUpdateProfile', params)

        db.commit()
        return jsonify({"message": "Profile updated successfully"})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    
    finally:
        cursor.close()
        db.close()


if __name__ == "__main__":
    app.run(debug = True)