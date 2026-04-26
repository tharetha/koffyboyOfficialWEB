from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from models.database import db
from models.models import Booking, BookingPricing
from routes.auth_routes import token_required
from services.email_service import send_booking_email

booking_bp = Blueprint('booking', __name__)

@booking_bp.route('/', methods=['POST'])
@token_required
def create_booking(current_user):
    data = request.get_json()
    event_type = data.get('event_type')
    event_date_str = data.get('event_date')
    start_time = data.get('start_time')
    end_time = data.get('end_time')
    location = data.get('location')
    notes = data.get('notes')

    if not all([event_type, event_date_str, location]):
        return jsonify({"error": "Missing required fields"}), 400

    try:
        event_date = datetime.strptime(event_date_str, '%Y-%m-%d')
    except ValueError:
        return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400

    # Check for double booking (including 1-day buffer)
    day_before = event_date - timedelta(days=1)
    day_after = event_date + timedelta(days=1)
    
    existing = Booking.query.filter(
        Booking.event_date.between(day_before, day_after),
        Booking.status == 'confirmed'
    ).first()
    
    if existing:
        return jsonify({"error": "Date is too close to another booking (1-day rest period required)"}), 400

    # Get price from BookingPricing model or default
    pricing = BookingPricing.query.filter_by(event_type=event_type).first()
    price = pricing.price if pricing else 1000.0

    # Ticketing fields
    is_ticketed = data.get('is_ticketed', False)
    title = data.get('title')
    ticket_price = data.get('ticket_price')
    capacity = data.get('capacity')
    payout_account = data.get('payout_account')
    notification_email = data.get('notification_email')
    terms_accepted = data.get('terms_accepted', False)

    new_booking = Booking(
        user_id=current_user.id,
        event_type=event_type,
        event_date=event_date,
        start_time=start_time,
        end_time=end_time,
        location=location,
        notes=notes,
        price=price,
        status='pending',
        is_ticketed=is_ticketed,
        title=title,
        ticket_price=float(ticket_price) if ticket_price else None,
        capacity=int(capacity) if capacity else 0,
        payout_account=payout_account,
        notification_email=notification_email,
        terms_accepted=terms_accepted,
        terms_accepted_at=datetime.utcnow() if terms_accepted else None
    )

    db.session.add(new_booking)
    db.session.commit()


    # Send Notification Email to Artist
    artist_email = "koffyboyOfficial@gmail.com"
    subject = f"New Booking Request: {event_type.capitalize()} on {event_date_str}"
    body = f"User {current_user.first_name} {current_user.last_name} requested a booking.\n"
    body += f"Date: {event_date_str}\n"
    body += f"Location: {location}\n"
    body += f"Time: {start_time} - {end_time}\n"
    body += f"Notes: {notes}\n"
    body += "Check the artist dashboard to confirm."
    
    send_booking_email(artist_email, subject, body)

    return jsonify({"message": "Booking request submitted successfully", "booking_id": new_booking.id}), 201

@booking_bp.route('/pricing', methods=['GET'])
def get_pricing():
    pricings = BookingPricing.query.all()
    results = {p.event_type: p.price for p in pricings}
    # Fallback to defaults if empty
    if not results:
        results = {
            'wedding': 1000,
            'show': 1500,
            'club': 800,
            'private': 500
        }
    return jsonify(results), 200

@booking_bp.route('/booked-dates', methods=['GET'])
def get_booked_dates():
    bookings = Booking.query.filter(Booking.status == 'confirmed').all()
    booked_dates = [b.event_date.strftime('%Y-%m-%d') for b in bookings]
    return jsonify({"booked_dates": booked_dates}), 200

@booking_bp.route('/availability', methods=['GET'])
def check_availability():
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({"error": "Date parameter is required"}), 400
    
    try:
        event_date = datetime.strptime(date_str, '%Y-%m-%d')
    except ValueError:
        return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400

    day_before = event_date - timedelta(days=1)
    day_after = event_date + timedelta(days=1)
    
    existing = Booking.query.filter(
        Booking.event_date.between(day_before, day_after),
        Booking.status == 'confirmed'
    ).first()
    
    is_available = not bool(existing)

    return jsonify({"available": is_available}), 200
