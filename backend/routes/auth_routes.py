from flask import Blueprint, request, jsonify, current_app
from flask_bcrypt import Bcrypt
from models.database import db
from models.models import User
import jwt
from datetime import datetime, timedelta
from functools import wraps

auth_bp = Blueprint('auth', __name__)
bcrypt = Bcrypt()

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(" ")[1]
        
        if not token:
            return jsonify({'error': 'Token is missing!'}), 401
        
        try:
            data = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = User.query.filter_by(id=data['user_id']).first()
        except Exception as e:
            return jsonify({'error': 'Token is invalid or expired!'}), 401
        
        return f(current_user, *args, **kwargs)
    
    return decorated

@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    phone_number = data.get('phone_number')
    password = data.get('password')
    first_name = data.get('first_name')
    last_name = data.get('last_name')
    email = data.get('email')

    if not all([phone_number, password, first_name, last_name]):
        return jsonify({"error": "Missing required fields"}), 400

    if User.query.filter_by(phone_number=phone_number).first():
        return jsonify({"error": "Phone number already registered"}), 400

    password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    new_user = User(
        first_name=first_name,
        last_name=last_name,
        phone_number=phone_number,
        email=email,
        password_hash=password_hash
    )

    db.session.add(new_user)
    db.session.commit()

    return jsonify({"message": "User created successfully"}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    phone_number = data.get('phone_number')
    password = data.get('password')

    if not phone_number or not password:
        return jsonify({"error": "Missing phone number or password"}), 400

    user = User.query.filter_by(phone_number=phone_number).first()
    
    if user and bcrypt.check_password_hash(user.password_hash, password):
        token = jwt.encode({
            'user_id': user.id,
            'exp': datetime.utcnow() + timedelta(days=7)
        }, current_app.config['SECRET_KEY'], algorithm="HS256")

        return jsonify({
            "message": "Login successful",
            "token": token,
            "user": {
                "id": user.id,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "is_subscribed": user.is_subscribed,
                "is_artist": user.is_artist
            }
        }), 200

    return jsonify({"error": "Invalid credentials"}), 401
