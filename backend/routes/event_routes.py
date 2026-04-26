from flask import Blueprint, request, jsonify, send_file
from models.database import db
from models.models import Booking, EventTicket
from routes.auth_routes import token_required
from services.email_service import send_booking_email
import qrcode
from io import BytesIO
import uuid
from datetime import datetime

event_bp = Blueprint('event', __name__)

@event_bp.route('/public', methods=['GET'])
def get_public_events():
    """Fetch all upcoming ticketed events for the public events page."""
    today = datetime.utcnow()
    events = Booking.query.filter(
        Booking.is_ticketed == True,
        Booking.status == 'confirmed',
        Booking.event_date >= today
    ).order_by(Booking.event_date.asc()).all()

    results = []
    for e in events:
        results.append({
            "id": e.id,
            "title": e.title or f"{e.event_type.capitalize()} Event",
            "date": e.event_date.strftime('%Y-%m-%d'),
            "time": f"{e.start_time} - {e.end_time}",
            "location": e.location,
            "ticket_price": e.ticket_price,
            "capacity": e.capacity,
            "tickets_sold": e.tickets_sold,
            "available": (e.capacity or 0) - (e.tickets_sold or 0)
        })
    return jsonify({"events": results}), 200

@event_bp.route('/hosted', methods=['GET'])
@token_required
def get_hosted_events(current_user):
    """Fetch events hosted by the logged-in user for their dashboard."""
    events = Booking.query.filter_by(user_id=current_user.id).order_by(Booking.event_date.desc()).all()
    
    results = []
    for e in events:
        expected_payout = 0
        if e.is_ticketed:
            total_revenue = e.tickets_sold * (e.ticket_price or 0)
            platform_fee = total_revenue * ((e.platform_fee_percentage or 5.0) / 100)
            expected_payout = total_revenue - platform_fee - e.price # Deduct booking cost
            
        results.append({
            "id": e.id,
            "type": e.event_type.capitalize(),
            "title": e.title,
            "date": e.event_date.strftime('%Y-%m-%d'),
            "status": e.status,
            "is_ticketed": e.is_ticketed,
            "tickets_sold": e.tickets_sold,
            "capacity": e.capacity,
            "ticket_price": e.ticket_price,
            "expected_payout": max(0, expected_payout),
            "payout_status": e.payout_status
        })
    return jsonify({"hosted_events": results}), 200

def generate_and_send_ticket(ticket_id):
    """Generates QR code and sends ticket email. Called from webhook."""
    ticket = EventTicket.query.get(ticket_id)
    if not ticket:
        return False
        
    event = Booking.query.get(ticket.booking_id)
    
    # Generate QR Code
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(ticket.qr_code_uuid)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save temporarily (in a real app, upload to S3/Firebase and link)
    # For now, we just construct the email body without attachments for simplicity
    # A real implementation would attach the BytesIO buffer to the MIME message
    
    subject = f"Your Ticket: {event.title or 'Koffyboy Event'}"
    body = f"Hi {ticket.buyer_name},\n\n"
    body += f"Here are the details for your upcoming event:\n"
    body += f"Event: {event.title}\n"
    body += f"Date: {event.event_date.strftime('%Y-%m-%d')}\n"
    body += f"Location: {event.location}\n\n"
    body += f"Your Ticket ID (QR Code UUID): {ticket.qr_code_uuid}\n\n"
    body += "Please show this ID or the QR code at the door."
    
    send_booking_email(ticket.buyer_email, subject, body)
    return True
