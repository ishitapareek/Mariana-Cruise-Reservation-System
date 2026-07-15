# Mariana Cruise Reservation System

![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)
![Flask](https://img.shields.io/badge/Flask-2.x-lightgrey.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat&logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=flat&logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black)

Mariana Cruise Reservation System is a robust, full-stack web application built to handle the booking and management of cruise trips. It provides users with a seamless interface to browse available cruises, select suites and activities, and manage their reservations securely. The system leverages a Flask backend and a complex MySQL database architecture utilizing stored procedures, functions, triggers, and views for efficient data management.

## 🌟 Features

- **User Authentication:** Secure registration and login using bcrypt for password hashing.
- **Profile Management:** Users can view and update their profile details (address, DOB, gender, mobile, etc.).
- **Cruise Browsing:** View available cruise itineraries, start and end dates.
- **Reservation System:**
  - Book a cruise and add accompanying passengers.
  - Choose a suite and specify the number of nights.
  - Opt into onboard activities.
- **Reservation Management:** View booking history, cost breakdown, and update pending reservations.
- **Payment Processing:** Integrated mock payment handling that automatically updates reservation statuses to "Confirmed".
- **Database-Driven Logic:** Heavy reliance on MySQL stored procedures and views to abstract business logic and prevent SQL injection.

## 🛠️ Technology Stack

- **Backend:** Python, Flask, Flask-CORS
- **Database:** MySQL
- **Dependencies:** `mysql-connector-python`, `bcrypt`
- **Frontend:** HTML, CSS, JavaScript (rendered via Flask templates)

## 📂 Project Structure

```
├── Database/
│   ├── Functions/                 # SQL User-defined Functions (e.g., Get_Total_Cost)
│   ├── Procedures/                # SQL Stored Procedures for CRUD operations
│   ├── Seed/                      # Initial seed data for the DB
│   ├── Tables/                    # Database schema definitions
│   ├── Triggers/                  # SQL Triggers (e.g., after_payment)
│   ├── Views/                     # SQL Views for complex data retrieval
│   ├── database-master-script.txt # Instructions for database creation
│   ├── database.sql               # Full database creation script
│   └── userdata_seed.sql          # Dummy user data
├── static/                        # CSS, JS, and image assets
├── templates/                     # HTML templates for the frontend
├── app.py                         # Flask application and API routes
├── db.py                          # Database connection and helper functions
└── requirements.txt               # Python dependencies
```

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- Python 3.8+
- MySQL Server (8.0+)
- `pip` (Python package manager)

### 1. Database Setup

The project relies heavily on a pre-configured MySQL database.

1. Open your preferred MySQL client (e.g., MySQL Workbench or CLI).
2. Follow the setup instructions detailed in `Database/database-master-script.txt` or simply run the aggregated scripts.
3. Generally, the execution order is:
   - Create Database (`Cruise_Reservation_System`)
   - Create Tables (respecting foreign key constraints)
   - Create Functions
   - Create Procedures
   - Create Triggers
   - Create Views
   - Insert Seed Data
4. **Update `db.py`**: Open `db.py` in the root folder and update the connection parameters (`host`, `user`, `password`) to match your local MySQL configuration.

### 2. Application Setup

1. Clone this repository (if applicable) or navigate to the project directory.
2. It's recommended to create a virtual environment:
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   ```
3. Install the dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the Flask application:
   ```bash
   python app.py
   ```
5. Open your web browser and navigate to `http://localhost:5000`.

## 🔌 API Endpoints

The backend provides several RESTful API endpoints for the frontend application:

### Authentication & User
- `POST /api/register` - Register a new user
- `POST /api/login` - Authenticate a user
- `GET /api/logout` - Clear user session
- `GET /api/me` - Get current user profile
- `PUT /api/profile` - Update user profile

### Cruise & Booking Data
- `GET /api/cruises` - Fetch all available cruises
- `GET /api/suites` - Fetch available suite types
- `GET /api/activities` - Fetch available activities

### Reservations
- `POST /api/book` - Create a new reservation
- `GET /api/my-bookings` - Fetch all bookings for the logged-in user
- `GET /api/reservation/<res_id>` - Get specific reservation details
- `PUT /api/reservation/<res_id>` - Update a pending reservation
- `GET /api/cost/<res_id>` - Get total cost for a reservation

### Payments
- `POST /api/pay` - Process payment for a reservation

## 🤝 Contributing

Contributions, issues, and feature requests are welcome.

## 📝 License

This project is created for educational purposes. Feel free to use and modify it as needed.
