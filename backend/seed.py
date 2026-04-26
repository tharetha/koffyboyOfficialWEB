from app import app
from models.database import db
from models.models import Album, Track, Product, BookingPricing, Highlight, ArtistProfile, User
from datetime import datetime
from flask_bcrypt import Bcrypt

def seed():
    with app.app_context():
        bcrypt = Bcrypt()
        # Clear existing data
        db.drop_all()
        db.create_all()

        # 0. Seed Artist User & Profile
        artist_user = User(
            first_name="Koffy",
            last_name="Boy",
            phone_number="+260999999999",
            email="koffyboyOfficial@gmail.com",
            password_hash=bcrypt.generate_password_hash("artist123").decode('utf-8'),
            is_artist=True
        )
        db.session.add(artist_user)
        
        profile = ArtistProfile(
            bio="Rising from the vibrant streets to the big stage, Koffyboy is more than just an artist—he's a movement. Blending unique afro-beats with modern pop influences, his music creates an unforgettable atmosphere.",
            profile_image_url="https://images.unsplash.com/photo-1520127875765-26525287a662?auto=format&fit=crop&q=80&w=800",
            social_links='{"instagram": "koffyboy", "youtube": "koffyboyofficial"}'
        )
        db.session.add(profile)

        # 1. Seed Booking Pricing
        pricing = [
            BookingPricing(event_type='wedding', price=1000.0),
            BookingPricing(event_type='show', price=1500.0),
            BookingPricing(event_type='club', price=800.0),
            BookingPricing(event_type='private', price=500.0),
            BookingPricing(event_type='custom', price=1200.0)
        ]
        db.session.bulk_save_objects(pricing)

        # 2. Seed Album & Tracks
        album1 = Album(
            title="The Beginning",
            cover_image_url="https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?auto=format&fit=crop&q=80&w=800",
            release_date=datetime(2026, 1, 1)
        )
        db.session.add(album1)
        db.session.commit()

        tracks = [
            Track(album_id=album1.id, title="Zaazuu Vibe", audio_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", preview_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", track_number=1),
            Track(album_id=album1.id, title="Midnight Run", audio_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3", preview_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3", track_number=2),
            Track(album_id=album1.id, title="Koffy Flow", audio_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3", preview_url="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3", track_number=3)
        ]
        db.session.bulk_save_objects(tracks)

        # 3. Seed Products
        products = [
            Product(name="Koffyboy Hoodie", description="Premium cotton hoodie with official logo.", price=250.0, category="Apparel", image_url="https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=400", stock=50),
            Product(name="Vibe Cap", description="Adjustable snapback with custom embroidery.", price=120.0, category="Accessories", image_url="https://images.unsplash.com/photo-1588850561407-ed78c282e89b?auto=format&fit=crop&q=80&w=400", stock=100),
            Product(name="Limited Vinyl", description="Signed 'The Beginning' album on 180g vinyl.", price=450.0, category="Music", image_url="https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&q=80&w=400", stock=20)
        ]
        db.session.bulk_save_objects(products)

        # 4. Seed Highlights
        highlights = [
            Highlight(image_url="https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?auto=format&fit=crop&q=80&w=1200", caption="Sold out show in Lusaka!"),
            Highlight(image_url="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=1200", caption="Midnight Vibe recording session.")
        ]
        db.session.bulk_save_objects(highlights)

        db.session.commit()
        print("Database seeded successfully!")

if __name__ == "__main__":
    seed()
