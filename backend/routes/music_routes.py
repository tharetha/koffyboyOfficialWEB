from flask import Blueprint, request, jsonify, current_app
from models.database import db
from models.models import Album, Track, User
import jwt

music_bp = Blueprint('music', __name__)

@music_bp.route('/albums', methods=['GET'])
def get_albums():
    albums = Album.query.all()
    results = []
    for album in albums:
        results.append({
            "id": album.id,
            "title": album.title,
            "cover_image_url": album.cover_image_url,
            "release_date": album.release_date.strftime("%Y-%m-%d"),
            "track_count": len(album.tracks)
        })
    return jsonify({"albums": results}), 200

@music_bp.route('/tracks', methods=['GET'])
def get_tracks():
    album_id = request.args.get('album_id')
    
    # Optional JWT check
    is_subscribed = False
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers['Authorization']
        if auth_header.startswith('Bearer '):
            token = auth_header.split(" ")[1]
    
    if token:
        try:
            data = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=["HS256"])
            user = User.query.get(data['user_id'])
            if user and user.is_subscribed:
                is_subscribed = True
        except:
            pass # Invalid token, treat as guest

    if album_id:
        tracks = Track.query.filter_by(album_id=album_id).order_by(Track.track_number).all()
    else:
        tracks = Track.query.all()

    results = []
    for track in tracks:
        results.append({
            "id": track.id,
            "album_id": track.album_id,
            "title": track.title,
            "track_number": track.track_number,
            "audio_url": track.audio_url if is_subscribed else track.preview_url,
            "is_preview": not is_subscribed
        })

    return jsonify({"tracks": results, "full_access": is_subscribed}), 200
