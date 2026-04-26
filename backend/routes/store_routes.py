from flask import Blueprint, request, jsonify
from models.database import db
from models.models import Product, Order, OrderItem
from routes.auth_routes import token_required
from services.email_service import send_booking_email # Reusing for receipt for now

store_bp = Blueprint('store', __name__)

@store_bp.route('/', methods=['GET'])
def get_products():
    products = Product.query.all()
    results = [
        {
            "id": p.id,
            "name": p.name,
            "description": p.description,
            "price": p.price,
            "image_url": p.image_url,
            "stock": p.stock
        } for p in products
    ]
    return jsonify({"products": results}), 200

@store_bp.route('/order', methods=['POST'])
@token_required
def create_order(current_user):
    data = request.get_json()
    items = data.get('items') # List of {product_id, quantity}
    
    if not items:
        return jsonify({"error": "No items in order"}), 400

    total_price = 0
    order_items = []
    
    for item in items:
        product = Product.query.get(item['product_id'])
        if not product or product.stock < item['quantity']:
            return jsonify({"error": f"Product {product.name if product else 'unknown'} is out of stock"}), 400
        
        price = product.price * item['quantity']
        total_price += price
        
        # Decrement stock
        product.stock -= item['quantity']
        
        order_item = OrderItem(
            product_id=product.id,
            quantity=item['quantity'],
            price_at_purchase=product.price
        )
        order_items.append(order_item)

    new_order = Order(
        user_id=current_user.id,
        total_price=total_price,
        status='pending'
    )
    
    for oi in order_items:
        new_order.items.append(oi)
        
    db.session.add(new_order)
    db.session.commit()

    # Send Receipt Email to Artist
    artist_email = "koffyboyOfficial@gmail.com"
    subject = f"New Order Recieved! Order #{new_order.id}"
    body = f"User {current_user.first_name} {current_user.last_name} placed a new order.\n"
    body += f"Total: ZMW {total_price}\n"
    body += f"Order ID: {new_order.id}\n"
    body += "Please check the artist dashboard to fulfill."
    
    send_booking_email(artist_email, subject, body)

    return jsonify({"message": "Order placed successfully", "order_id": new_order.id}), 201

@store_bp.route('/my-orders', methods=['GET'])
@token_required
def get_my_orders(current_user):
    orders = Order.query.filter_by(user_id=current_user.id).order_by(Order.created_at.desc()).all()
    results = []
    for o in orders:
        items = []
        for item in o.items:
            product = Product.query.get(item.product_id)
            items.append({
                "product_name": product.name if product else "Unknown",
                "quantity": item.quantity,
                "price": item.price_at_purchase
            })
        
        results.append({
            "id": o.id,
            "total_price": o.total_price,
            "status": o.status,
            "created_at": o.created_at.strftime("%Y-%m-%d %H:%M"),
            "items": items
        })
    
    return jsonify({"orders": results}), 200
