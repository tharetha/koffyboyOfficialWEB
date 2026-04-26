import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO
from models.database import db
from routes.auth_routes import auth_bp
from routes.booking_routes import booking_bp
from routes.music_routes import music_bp
from routes.store_routes import store_bp
from routes.payment_routes import payment_bp
from routes.artist_mgmt_routes import artist_mgmt_bp
from routes.event_routes import event_bp
from services.scheduler import init_scheduler

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev_secret_key_change_in_prod')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///../database/koffyboy.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

CORS(app, resources={r"/api/*": {"origins": "*"}})
socketio = SocketIO(app, cors_allowed_origins="*")

db.init_app(app)

# Register Blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(booking_bp, url_prefix='/api/bookings')
app.register_blueprint(music_bp, url_prefix='/api/music')
app.register_blueprint(store_bp, url_prefix='/api/store')
app.register_blueprint(payment_bp, url_prefix='/api/payments')
app.register_blueprint(artist_mgmt_bp, url_prefix='/api/artist-mgmt')
app.register_blueprint(event_bp, url_prefix='/api/events')

@app.route('/')
def index():
    return jsonify({"message": "KoffyboyOfficial API is running!"})

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        init_scheduler(app)
    socketio.run(app, host='0.0.0.0', debug=True, port=5000)  # 0.0.0.0 = reachable on local network
