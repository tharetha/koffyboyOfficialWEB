from app import app
from models.database import db
from models.models import Album, Track, Product, Booking, EventTicket, ArtistProfile

with app.app_context():
    print("Clearing mock content data...")
    
    # We clear data from bottom up to avoid foreign key constraints
    EventTicket.query.delete()
    Booking.query.delete()
    
    # Store
    # Assuming Order and OrderItem are tied to users but referencing products.
    # To be safe, we might need to clear orders too if they reference products we are deleting.
    from models.models import OrderItem, Order
    OrderItem.query.delete()
    Order.query.delete()
    Product.query.delete()
    
    # Music
    Track.query.delete()
    Album.query.delete()
    
    # Profile / Highlights
    ArtistProfile.query.delete()
    
    db.session.commit()
    print("Database cleared of mock content! User accounts have been preserved.")
