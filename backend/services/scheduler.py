from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
from models.database import db
from models.models import User, Subscription, BillingTransaction, PaymentMethod
from services.email_service import send_booking_email
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def charge_subscriptions(app):
    with app.app_context():
        logger.info("Running autopay job...")
        today = datetime.utcnow()
        
        # Find active subscriptions due today
        due_subs = Subscription.query.filter(
            Subscription.status == 'active',
            Subscription.next_billing_date <= today
        ).all()
        
        for sub in due_subs:
            method = PaymentMethod.query.get(sub.payment_method_id)
            if not method:
                continue
                
            # SIMULATION: Try to charge (replace with real API call)
            # success = call_payment_gateway(method, sub.price)
            success = True # Simulation
            
            if success:
                sub.next_billing_date = today + timedelta(days=30)
                sub.status = 'active'
                sub.grace_expires = None
                
                transaction = BillingTransaction(
                    subscription_id=sub.id,
                    amount=sub.price,
                    status='success'
                )
                db.session.add(transaction)
                logger.info(f"Successfully charged user {sub.user_id}")
            else:
                # Failed: enter grace period
                sub.status = 'grace'
                sub.grace_expires = today + timedelta(days=7)
                
                transaction = BillingTransaction(
                    subscription_id=sub.id,
                    amount=sub.price,
                    status='failed',
                    error_message="Insufficient funds or gateway error"
                )
                db.session.add(transaction)
                logger.warning(f"Payment failed for user {sub.user_id}. Entering grace period.")
                
                # Notify User
                user = User.query.get(sub.user_id)
                if user and user.email:
                    subject = "⚠️ Action Required: Subscription Payment Failed"
                    body = f"Hi {user.first_name},\n\nWe were unable to process your monthly subscription payment of ZMW 20.\n"
                    body += "You have entered a 7-day grace period. Please update your payment method to avoid losing access to full tracks."
                    send_booking_email(user.email, subject, body)
                
        db.session.commit()

def check_grace_expiry(app):
    with app.app_context():
        logger.info("Checking grace period expiries...")
        today = datetime.utcnow()
        
        expired_subs = Subscription.query.filter(
            Subscription.status == 'grace',
            Subscription.grace_expires <= today
        ).all()
        
        for sub in expired_subs:
            sub.status = 'suspended'
            user = User.query.get(sub.user_id)
            if user:
                user.is_subscribed = False
            logger.warning(f"Grace period expired for user {sub.user_id}. Access suspended.")
            
        db.session.commit()

def init_scheduler(app):
    scheduler = BackgroundScheduler()
    # Run every 24 hours (or more frequently for testing)
    scheduler.add_job(func=charge_subscriptions, trigger="interval", hours=24, args=[app])
    scheduler.add_job(func=check_grace_expiry, trigger="interval", hours=24, args=[app])
    scheduler.start()
    logger.info("Scheduler started.")
