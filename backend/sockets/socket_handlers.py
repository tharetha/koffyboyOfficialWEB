from flask_socketio import emit
from app import socketio

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

def notify_booking_update(booking_data):
    """
    Emit a real-time event when a new booking is made or status changes.
    The artist dashboard will listen to 'booking_update' event.
    """
    socketio.emit('booking_update', booking_data)
