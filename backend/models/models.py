from datetime import datetime
from models.database import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    phone_number = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=True)
    password_hash = db.Column(db.String(128), nullable=False)
    is_subscribed = db.Column(db.Boolean, default=False)
    is_artist = db.Column(db.Boolean, default=False) # For artist dashboard access
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    bookings = db.relationship('Booking', backref='user', lazy=True)
    payment_methods = db.relationship('PaymentMethod', backref='user', lazy=True)
    subscription = db.relationship('Subscription', backref='user', uselist=False, lazy=True)
    orders = db.relationship('Order', backref='user', lazy=True)
    feedbacks = db.relationship('AppFeedback', backref='user', lazy=True)

class PaymentMethod(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    method_type = db.Column(db.String(50), nullable=False) # 'momo_mtn', 'momo_airtel', 'card_visa', 'card_mastercard'
    token = db.Column(db.String(255), nullable=False) # Phone number for MoMo, Stripe token for Cards
    last4 = db.Column(db.String(4), nullable=True) # Last 4 digits for cards
    is_default = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Subscription(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    payment_method_id = db.Column(db.Integer, db.ForeignKey('payment_method.id'), nullable=False)
    status = db.Column(db.String(20), default='active') # active, grace, suspended, cancelled
    price = db.Column(db.Float, default=20.0) # 20 ZMW
    next_billing_date = db.Column(db.DateTime, nullable=False)
    grace_expires = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    transactions = db.relationship('BillingTransaction', backref='subscription', lazy=True)

class BillingTransaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    subscription_id = db.Column(db.Integer, db.ForeignKey('subscription.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), nullable=False) # success, failed
    attempt_date = db.Column(db.DateTime, default=datetime.utcnow)
    error_message = db.Column(db.String(255), nullable=True)

class Album(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    cover_image_url = db.Column(db.String(255), nullable=True)
    release_date = db.Column(db.DateTime, default=datetime.utcnow)
    
    tracks = db.relationship('Track', backref='album', lazy=True)

class Track(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    album_id = db.Column(db.Integer, db.ForeignKey('album.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    audio_url = db.Column(db.String(255), nullable=False)
    preview_url = db.Column(db.String(255), nullable=False) # 30s snippet
    track_number = db.Column(db.Integer, nullable=False)
    is_sample = db.Column(db.Boolean, default=False) # If true, shows up as free full track on the homepage

class ArtistProfile(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    bio = db.Column(db.Text, nullable=True)
    profile_image_url = db.Column(db.String(255), nullable=True)
    social_links = db.Column(db.Text, nullable=True) # JSON string

class BookingPricing(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    event_type = db.Column(db.String(50), unique=True, nullable=False) # wedding, show, club, private
    price = db.Column(db.Float, nullable=False)

class Booking(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    event_type = db.Column(db.String(50), nullable=False) # wedding, show, club, private
    event_date = db.Column(db.DateTime, nullable=False)
    start_time = db.Column(db.String(10), nullable=True)
    end_time = db.Column(db.String(10), nullable=True)
    location = db.Column(db.String(200), nullable=False)
    notes = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='pending') # pending, confirmed, completed, cancelled
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # --- Ticketing & Public Event Extensions ---
    is_ticketed = db.Column(db.Boolean, default=False)
    title = db.Column(db.String(100), nullable=True)
    ticket_price = db.Column(db.Float, nullable=True)
    capacity = db.Column(db.Integer, nullable=True, default=0)
    tickets_sold = db.Column(db.Integer, nullable=True, default=0)
    
    # Financial & Legal
    terms_accepted = db.Column(db.Boolean, default=False)
    terms_accepted_at = db.Column(db.DateTime, nullable=True)
    platform_fee_percentage = db.Column(db.Float, default=5.0) # 5% default
    payout_account = db.Column(db.String(100), nullable=True) # MoMo number or Bank info
    notification_email = db.Column(db.String(120), nullable=True)
    payout_status = db.Column(db.String(20), default='pending') # pending, paid

    tickets = db.relationship('EventTicket', backref='event', lazy=True)

class Highlight(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    image_url = db.Column(db.String(255), nullable=False)
    caption = db.Column(db.String(200), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)
    category = db.Column(db.String(50), nullable=True)
    image_url = db.Column(db.String(255), nullable=True)
    images_json = db.Column(db.Text, nullable=True) # JSON array of image URLs
    stock = db.Column(db.Integer, default=0)
    
    order_items = db.relationship('OrderItem', backref='product', lazy=True)

class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='pending') # pending, paid, shipped, delivered
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    items = db.relationship('OrderItem', backref='order', lazy=True)

class OrderItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    price_at_purchase = db.Column(db.Float, nullable=False)

class AppFeedback(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False) # 1 to 5
    feedback_text = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class EventTicket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    booking_id = db.Column(db.Integer, db.ForeignKey('booking.id'), nullable=False)
    buyer_name = db.Column(db.String(100), nullable=False)
    buyer_email = db.Column(db.String(120), nullable=False)
    qr_code_uuid = db.Column(db.String(64), unique=True, nullable=False)
    price_paid = db.Column(db.Float, nullable=False)
    platform_fee_amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='valid') # valid, scanned, refunded
    purchased_at = db.Column(db.DateTime, default=datetime.utcnow)
