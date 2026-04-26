from flask import Blueprint, request, jsonify
from models.database import db
from models.models import Highlight, Album, Track, Product, Booking, Order, ArtistProfile
from routes.auth_routes import token_required
from datetime import datetime

from functools import wraps

artist_mgmt_bp = Blueprint('artist_mgmt', __name__)

def artist_only(f):
    @wraps(f)
    @token_required
    def decorated(current_user, *args, **kwargs):
        if not current_user.is_artist:
            return jsonify({"error": "Artist access required"}), 403
        return f(current_user, *args, **kwargs)
    return decorated

# ── Public Endpoints ──────────────────────────────────────────
@artist_mgmt_bp.route('/highlights', methods=['GET'])
def get_highlights():
    highlights = Highlight.query.all()
    return jsonify([{"image_url": h.image_url, "caption": h.caption} for h in highlights]), 200

@artist_mgmt_bp.route('/profile', methods=['GET'])
def get_profile():
    profile = ArtistProfile.query.first()
    if not profile:
        return jsonify({"bio": "No bio yet", "profile_image_url": None, "social_links": None}), 200
    return jsonify({
        "bio": profile.bio,
        "profile_image_url": profile.profile_image_url,
        "social_links": profile.social_links
    }), 200

# ── Highlights (Protected) ──────────────────────────────────────
@artist_mgmt_bp.route('/highlights', methods=['POST'])
@artist_only
def add_highlight(current_user):
    data = request.get_json()
    new_h = Highlight(
        image_url=data.get('image_url'),
        caption=data.get('caption')
    )
    db.session.add(new_h)
    db.session.commit()
    return jsonify({"message": "Highlight added"}), 201

# ── Music ────────────────────────────────────────────────────────
@artist_mgmt_bp.route('/albums', methods=['POST'])
@artist_only
def add_album(current_user):
    data = request.get_json()
    new_a = Album(
        title=data.get('title'),
        cover_image_url=data.get('cover_image_url'),
        release_date=datetime.strptime(data.get('release_date'), '%Y-%m-%d') if data.get('release_date') else datetime.utcnow()
    )
    db.session.add(new_a)
    db.session.commit()
    return jsonify({"message": "Album created", "id": new_a.id}), 201

@artist_mgmt_bp.route('/tracks', methods=['POST'])
@artist_only
def add_track(current_user):
    data = request.get_json()
    new_t = Track(
        album_id=data.get('album_id'),
        title=data.get('title'),
        audio_url=data.get('audio_url'),
        preview_url=data.get('preview_url'),
        track_number=data.get('track_number'),
        is_sample=data.get('is_sample', False)
    )
    db.session.add(new_t)
    db.session.commit()
    return jsonify({"message": "Track added"}), 201

# ── Store ────────────────────────────────────────────────────────
@artist_mgmt_bp.route('/products', methods=['POST'])
@artist_only
def add_product(current_user):
    data = request.get_json()
    new_p = Product(
        name=data.get('name'),
        description=data.get('description'),
        price=data.get('price'),
        image_url=data.get('image_url'),
        stock=data.get('stock'),
        category=data.get('category')
    )
    db.session.add(new_p)
    db.session.commit()
    return jsonify({"message": "Product added"}), 201

# ── Bookings & Orders Management ────────────────────────────────
@artist_mgmt_bp.route('/bookings/<int:id>', methods=['PATCH'])
@artist_only
def update_booking(current_user, id):
    data = request.get_json()
    booking = Booking.query.get_or_404(id)
    if 'status' in data:
        booking.status = data['status'] # confirmed, cancelled
    db.session.commit()
    return jsonify({"message": "Booking updated"}), 200

@artist_mgmt_bp.route('/orders/<int:id>', methods=['PATCH'])
@artist_only
def update_order(current_user, id):
    data = request.get_json()
    order = Order.query.get_or_404(id)
    if 'status' in data:
        order.status = data['status'] # confirmed, completed
    db.session.commit()
    return jsonify({"message": "Order updated"}), 200

# ── Artist Profile ──────────────────────────────────────────────
@artist_mgmt_bp.route('/profile', methods=['PATCH'])
@artist_only
def update_profile(current_user):
    data = request.get_json()
    profile = ArtistProfile.query.first()
    if not profile:
        profile = ArtistProfile()
        db.session.add(profile)
    
    if 'bio' in data: profile.bio = data['bio']
    if 'profile_image_url' in data: profile.profile_image_url = data['profile_image_url']
    if 'social_links' in data: profile.social_links = data['social_links']
    
    db.session.commit()
    return jsonify({"message": "Profile updated"}), 200
