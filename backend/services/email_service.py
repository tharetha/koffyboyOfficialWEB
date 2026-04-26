import smtplib
from email.mime.text import MIMEText
import os

def send_booking_email(to_email, subject, body):
    """
    Sends a basic email notification using SMTP.
    Requires SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD in env.
    """
    smtp_server = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
    smtp_port = int(os.environ.get('SMTP_PORT', 587))
    smtp_user = os.environ.get('SMTP_USERNAME')
    smtp_password = os.environ.get('SMTP_PASSWORD')

    if not all([smtp_user, smtp_password]):
        print("SMTP credentials not configured. Skipping email sending.")
        return False

    try:
        msg = MIMEText(body)
        msg['Subject'] = subject
        msg['From'] = smtp_user
        msg['To'] = to_email

        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.send_message(msg)
        server.quit()
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False
