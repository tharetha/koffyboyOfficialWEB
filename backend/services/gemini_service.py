import os
import google.generativeai as genai

def init_gemini():
    api_key = os.environ.get("GEMINI_API_KEY")
    if api_key:
        genai.configure(api_key=api_key)

def get_artist_insights(stats):
    """
    Sends aggregated stats to Gemini and returns business insights.
    """
    try:
        model = genai.GenerativeModel('gemini-pro')
        prompt = f"""
        You are an AI business manager for a music artist.
        Analyze the following statistics and provide 3 actionable insights or recommendations:
        - Total Users: {stats.get('total_users', 0)}
        - Active Bookings: {stats.get('active_bookings', 0)}
        - Total Revenue Estimated: ${stats.get('revenue', 0)}
        
        Keep the response concise and formatted as a bulleted list.
        """
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return "Insight generation temporarily unavailable."
