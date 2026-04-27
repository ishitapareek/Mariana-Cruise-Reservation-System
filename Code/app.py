from flask import Flask, request, jsonify, render_template, session
from flask_cors import CORS
import bcrypt
from db import get_db, call_proc, execute_proc

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

    address = data.get("address", None)
    dob = data.get("dob", None)
    gender = data.get("gender", None)

    if not name or not email or not password:
        return jsonify({"error": "Missing fields"}), 400

    hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())

    try:
        execute_proc("Register_User", (name, email, mobile, hashed.decode(), address, dob, gender))
        return jsonify({"message": "User registered successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route("/api/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    user = call_proc('uspGetEmail', (email,), fetch="one")

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


@app.route("/api/cruises", methods=["GET"])
def get_cruises():
    cruises = call_proc('uspGetCruises')

    for c in cruises:
        if c.get("Start_Date"):
            c["Start_Date"] = str(c["Start_Date"])
        if c.get("End_Date"):
            c["End_Date"] = str(c["End_Date"])

    return jsonify(cruises)


@app.route("/api/book", methods=["POST"])
def book():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    cruise_id = data.get("cruise_id")
    members = data.get("members")
    passengers = data.get("passengers", [])
    suite_code = data.get("suite_code")
    suite_nights = data.get("suite_nights", 1)
    activities = data.get("activities", [])

    if not cruise_id or not members:
        return jsonify({"error": "Missing cruise_id or members"}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.callproc("Create_Reservation", (session["user_id"], cruise_id, members))
        
        result = None
        for r in cursor.stored_results():
            result = r.fetchone()

        res_id = result["id"] if result else None
        
        if res_id:
            for p in passengers:
                name = p.get("name", "").strip()
                if name:
                    cursor.callproc('uspInsertPassenger', (res_id, name))

            if suite_code:
                cursor.callproc('uspInsertUserSuite', (res_id, suite_code, suite_nights))

            for act_code in activities:
                cursor.callproc('uspInsertUserActivity', (res_id, act_code))

        db.commit()
        return jsonify({"message": "Booking successful", "reservation_id": res_id})
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        db.close()


@app.route("/api/my-bookings", methods=["GET"])
def my_bookings():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    bookings = call_proc('uvMyBookings', (session["user_id"],))

    for b in bookings:
        if b.get("Start_Date"):
            b["Start_Date"] = str(b["Start_Date"])  
        if b.get("End_Date"):
            b["End_Date"] = str(b["End_Date"])

        res_id = b["Reservation_Id"]
        b["passengers"] = call_proc('uspGetPassengers', (res_id,))
        b["suites"] = call_proc('uspGetUserSuites', (res_id,))
        
        act_rows = call_proc('uspGetUserActivities', (res_id,))
        b["activities"] = [r["Activity_Code"] for r in act_rows]

    return jsonify(bookings)


@app.route("/api/pay", methods=["POST"])
def pay():
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    data = request.json
    reservation_id = data.get("reservation_id")
    amount = data.get("amount")

    if not reservation_id or not amount:
        return jsonify({"error": "Missing reservation_id or amount"}), 400

    reservation = call_proc('uspGetUser', (session["user_id"], reservation_id), fetch="one")

    if not reservation:
        return jsonify({"error": "Reservation not found"}), 404

    try:
        execute_proc('Make_Payment', (reservation_id, amount))
        return jsonify({"message": "Payment successful"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route("/api/cost/<int:res_id>", methods=["GET"])
def get_cost(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    reservation = call_proc('uspGetUser', (session["user_id"], res_id), fetch="one")

    if not reservation:
        return jsonify({"error": "Reservation not found"}), 404

    cost = call_proc('uspGetTotalCost', (res_id,), fetch="one")
    return jsonify({"total": cost["Total_Cost"] if cost else 0})


@app.route("/api/suites", methods=["GET"])
def get_suites():
    suites = call_proc('uspGetSuites')
    return jsonify(suites)


@app.route("/api/activities", methods=["GET"])
def get_activities():
    activities = call_proc('uspGetActivies')
    return jsonify(activities)


@app.route("/api/reservation/<int:res_id>", methods=["GET"])
def get_reservation(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    res = call_proc('uspGetReservationDetails', (res_id, session["user_id"]), fetch="one")

    if not res:
        return jsonify({"error": "Reservation not found"}), 404

    if res.get("Start_Date"):
        res["Start_Date"] = str(res["Start_Date"])
    if res.get("End_Date"):
        res["End_Date"] = str(res["End_Date"])

    res["passengers"] = call_proc('uspGetPassengers', (res_id,))
    res["suites"] = call_proc('uspGetUserSuites', (res_id,))

    act_rows = call_proc('uspGetUserActivities', (res_id,))
    res["activities"] = [r["Activity_Code"] for r in act_rows]

    cost_result = call_proc('uspGetTotalCost', (res_id,), fetch="one")
    res["Total_Cost"] = cost_result["Total_Cost"] if cost_result else 0

    return jsonify(res)


@app.route("/api/reservation/<int:res_id>", methods=["PUT"])
def update_reservation(res_id):
    if "user_id" not in session:
        return jsonify({"error": "Not logged in"}), 401

    existing = call_proc('uspGetUser', (session["user_id"], res_id), fetch="one")

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

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
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

    user = call_proc('uspGetMe', (session["user_id"],), fetch="one")
        
    if user and user.get("DOB"):
        user["DOB"] = str(user["DOB"])

    return jsonify({"user": user})


@app.route("/api/profile", methods=["PUT"])
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

    hashed = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt()) if new_password else ""

    params = (name, email, mobile, hashed.decode() if isinstance(hashed, bytes) else hashed, address, dob, gender, session["user_id"])
    
    try:
        execute_proc('uspUpdateProfile', params)
        return jsonify({"message": "Profile updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    app.run(debug=True)