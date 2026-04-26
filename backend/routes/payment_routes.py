import os
import requests
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime, timedelta
from models.database import db
from models.models import User, PaymentMethod, Subscription, BillingTransaction, Order
from routes.auth_routes import token_required

payment_bp = Blueprint('payment', __name__)

# Paystack Configuration (Placeholders)
PAYSTACK_SECRET_KEY = os.environ.get('PAYSTACK_SECRET_KEY', 'sk_test_koffyboy_placeholder')
PAYSTACK_BASE_URL = 'https://api.paystack.co'

@payment_bp.route('/initialize', methods=['POST'])
def initialize_payment():
    """
    Starts a Paystack transaction.
    Expects: {'amount': 20.0, 'email': 'user@example.com', 'metadata': {...}}
    """
    # Attempt to get user from token if provided
    current_user = None
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers['Authorization']
        if auth_header.startswith('Bearer '):
            token = auth_header.split(" ")[1]
            if token != 'guest_token':
                import jwt
                from app import app
                try:
                    data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
                    current_user = User.query.get(data['user_id'])
                except:
                    pass

    data = request.get_json()
    amount = data.get('amount')
    email = data.get('email')
    if current_user and not email:
        email = current_user.email

    metadata = data.get('metadata', {}) # e.g. {'type': 'subscription'} or {'type': 'order', 'order_id': 5}

    if not amount:
        return jsonify({"error": "Amount is required"}), 400

    # Paystack expects amount in sub-units (Ngwee/Cents), so multiply by 100
    paystack_payload = {
        "email": email,
        "amount": int(float(amount) * 100),
        "currency": "ZMW",
        "metadata": metadata,
        "callback_url": "http://localhost:8080/account.html" # Where user goes after paying
    }

    headers = {
        "Authorization": f"Bearer {PAYSTACK_SECRET_KEY}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(f"{PAYSTACK_BASE_URL}/transaction/initialize", json=paystack_payload, headers=headers)
        res_data = response.json()
        
        if res_data.get('status'):
            return jsonify({
                "checkout_url": res_data['data']['authorization_url'],
                "reference": res_data['data']['reference']
            }), 200
        else:
            return jsonify({"error": res_data.get('message', 'Paystack initialization failed')}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@payment_bp.route('/webhook', methods=['POST'])
def paystack_webhook():
    """
    Paystack calls this when a payment is successful.
    We don't use token_required here because it's a server-to-server call.
    """
    # In production, you should verify the Paystack signature header (x-paystack-signature)
    data = request.get_json()
    
    if data.get('event') == 'charge.success':
        payload = data['data']
        reference = payload['reference']
        metadata = payload['metadata']
        amount_paid = payload['amount'] / 100
        email = payload['customer']['email']
        
        # Note: 'user' might be None for guest ticket purchases
        user = User.query.filter_by(email=email).first()

        # 1. Handle Subscription
        if metadata.get('type') == 'subscription':
            if not user:
                return jsonify({"status": "user not found"}), 404
            user.is_subscribed = True
            
            # Update or create subscription
            sub = Subscription.query.filter_by(user_id=user.id).first()
            if not sub:
                sub = Subscription(
                    user_id=user.id,
                    status='active',
                    price=amount_paid,
                    next_billing_date=datetime.utcnow() + timedelta(days=30)
                )
                db.session.add(sub)
            else:
                sub.status = 'active'
                sub.next_billing_date = datetime.utcnow() + timedelta(days=30)
            
            # Log Transaction
            transaction = BillingTransaction(
                subscription_id=sub.id if sub.id else 0, # sub.id might be None until commit
                amount=amount_paid,
                status='success'
            )
            db.session.add(transaction)

        # 2. Handle Store Order
        elif metadata.get('type') == 'order':
            order_id = metadata.get('order_id')
            from models.models import Order
            order = Order.query.get(order_id)
            if order:
                order.status = 'paid'

        # 3. Handle Event Ticket
        elif metadata.get('type') == 'ticket':
            event_id = metadata.get('event_id')
            buyer_name = metadata.get('buyer_name', 'Guest')
            
            from models.models import Booking, EventTicket
            import uuid
            
            event = Booking.query.get(event_id)
            if event and event.is_ticketed:
                # Create the ticket
                ticket_uuid = str(uuid.uuid4())
                platform_fee = amount_paid * ((event.platform_fee_percentage or 5.0) / 100.0)
                
                new_ticket = EventTicket(
                    booking_id=event.id,
                    buyer_name=buyer_name,
                    buyer_email=email,
                    qr_code_uuid=ticket_uuid,
                    price_paid=amount_paid,
                    platform_fee_amount=platform_fee
                )
                db.session.add(new_ticket)
                
                # Update event capacity
                event.tickets_sold = (event.tickets_sold or 0) + 1
                
                db.session.commit() # Commit so we have ticket ID
                
                # Trigger QR email
                from routes.event_routes import generate_and_send_ticket
                generate_and_send_ticket(new_ticket.id)
                return jsonify({"status": "success"}), 200

        db.session.commit()
        return jsonify({"status": "success"}), 200

    return jsonify({"status": "ignored"}), 200

@payment_bp.route('/status', methods=['GET'])
@token_required
def get_status(current_user):
    sub = Subscription.query.filter_by(user_id=current_user.id).first()
    if not sub:
        return jsonify({"is_subscribed": False}), 200
    
    return jsonify({
        "is_subscribed": current_user.is_subscribed,
        "status": sub.status,
        "next_billing_date": sub.next_billing_date.strftime('%Y-%m-%d'),
        "grace_expires": sub.grace_expires.strftime('%Y-%m-%d') if sub.grace_expires else None
    }), 200
