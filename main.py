from flask import Flask, request, jsonify
from flask_cors import CORS
import speech_recognition as sr
import nltk
from nltk.tokenize import word_tokenize
from nltk.stem import PorterStemmer
from nltk.corpus import stopwords
import webbrowser
import pyttsx3
import os
import datetime
from datetime import datetime, timedelta
import time
import requests
import json
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import re
import pygame
from playsound import playsound
from dotenv import load_dotenv
import pywhatkit
import pyautogui
import google.generativeai as genai
import cv2

app = Flask(__name__)
CORS(app)

load_dotenv('API_KEYS.env')

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

#Creating the Gemini model with configuration
generation_config = {
    "temperature": 1,
    "top_p": 0.95,
    "top_k": 64,
    "max_output_tokens": 8192,
    "response_mime_type": "text/plain",
}
safety_settings = [
    {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
]

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash-latest",
    safety_settings=safety_settings,
    generation_config=generation_config,
)

chat_session = model.start_chat(history=[])


nltk.download('punkt')
nltk.download('stopwords')

old_news = []

listening = False
recognizer = sr.Recognizer()

def process_text(text):
    # Tokenizing the text
    tokens = word_tokenize(text)
    print(f"Tokens: {tokens}")

    #Removing stop words
    stop_words = set(stopwords.words('english'))
    filtered_tokens = [token for token in tokens if token not in stop_words]
    print(f"Tokens after stop word removal: {filtered_tokens}")

    # Stemming the tokens
    stemmer = PorterStemmer()
    stems = [stemmer.stem(token) for token in tokens]
    print(f"Stemmed tokens: {stems}")

    # Joining the stemmed tokens back into string
    stemmed_text = ''.join(stems)
    return stemmed_text


def say(text):
    engine = pyttsx3.init()
    voices = engine.getProperty('voices')
    engine.setProperty('voice', voices[1].id)
    rate = engine.getProperty('rate')
    print(rate)
    engine.setProperty('rate', 150)

    sentences = text.split('. ')
    for i in range(len(sentences)):
        sentences[i] += '.'
    text_with_pauses = ', '.join(sentences)
    engine.say(text_with_pauses)
    engine.runAndWait()


def takecommand():
    r = sr.Recognizer()
    with sr.Microphone() as source:
        r.pause_threshold = 1
        audio = r.listen(source)
        try:
            print("Recognizing")
            query = r.recognize_google(audio, language="en-in")
            print(f"User said: {query}")

            # processing the user's input
            processed_query = process_text(query)

            return query, processed_query
        except Exception as e:
            print(f"Error: {str(e)}")
            response = "I’m sorry, I’m having trouble understanding your request. Could you please repeat?"
            say(response)
            return "", "", 'en'

# Retrieving Weather data

def get_weather(city_name, api_key):
    base_url = "http://api.openweathermap.org/data/2.5/weather?"
    complete_url = f"{base_url}appid={api_key}&q={city_name}"
    try:
        response = requests.get(complete_url)
        response.raise_for_status()  # it raises a http error if the response status is 404, 503
    except requests.exceptions.RequestException as e:
        print(f"Error:{str(e)}")
        return "Weather data not found"
    weather_data = response.json()

    if weather_data["cod"] != "404":
        main_data = weather_data["main"]
        temperature = main_data["temp"] - 273.15  # Converting temperature from kelvin to celsius
        pressure = main_data["pressure"]
        humidity = main_data["humidity"]
        wind_speed = weather_data["wind"]["speed"] if "wind" in weather_data and "speed" in weather_data["wind"] else "Wind speed data not available"
        weather_desc = weather_data["weather"][0]["description"]
        return (temperature, pressure, humidity, wind_speed, weather_desc)
    else:
        return "Weather data not found."

# Fetching News
def get_news(api_key, query):
    url = f"https://newsapi.org/v2/everything?q={query}&apikey={api_key}"
    response = requests.get(url)
    if response.status_code != 200:  # checking if the API request was successful
        print(f"API request failed with status code{response.status_code}")
        print(f"Response Text: {response.text}")
        return "I’m sorry, but I’m currently unable to retrieve the news"
    else:
        news_data = response.json()
        articles = news_data["articles"]
        news = []
        for article in articles:
            news_item = {
                "title": article["title"],
                "description": article["description"],
                "content": article["content"] if "content" in article else "Content not available",
                "url": article["url"],
            }
            if news_item not in old_news:
                old_news.append(news_item)
                news.append(news_item)
        return news

# Sending an Email
def send_email(subject, message, to, gmail_user, gmail_password):
    try:
        msg = MIMEMultipart()
        msg['FROM'] = gmail_user
        msg['To'] = to
        msg['Subject'] = subject
        msg.attach(MIMEText(message, 'plain'))
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(gmail_user, gmail_password)
        print("Logged in successfully")
        text = msg.as_string()
        server.sendmail(gmail_user, to, text)  # Sending the email
        server.quit()
        print("Email sent successfully!")
    except smtplib.SMTPAuthenticationError:
        print("SMTPAuthenticationError occurred")
        response = "I'm sorry, but the email address or password provided is incorrect"\
                   "Please check your credentials and try again."
        say(response)
    except smtplib.SMTPRecipientsRefused:
        response = "I'm sorry, but the recipient's email addre ss was refused. Please check if the email address is correct."
        say(response)
    except smtplib.SMTPSenderRefused:
        response = "I'm sorry, but the sender's address was refused. Please check if your email address is correct."
        say(response)
    except smtplib.SMTPException as e:
        response = "I'm sorry, but an error occurred while sending the email. Please try again later."
        say(response)
        print(f"Failed to send email: {str(e)}")

def email_command():
    for attempt in range(2):  # Allowing two attempts
        response = "Sure, I can help you with that. Please tell me the recipient's email address. "
        say(response)
        to, _ = takecommand()
        to = to.replace(" ", "").replace("at", "@").lower()  # Removing spaces and Converting to lower case
        response = f"You said the email address is {to}. is that correct?"
        say(response)
        confirmation, _ = takecommand()
        confirmation = confirmation.lower()
        if 'yes' in confirmation or 'yeah' in confirmation:
            response = "Great! Now, please tell me the subject of your email."
            say(response)
            subject, _ = takecommand()
            response = "And what would you like to say in your email?"
            say(response)
            message, _ = takecommand()
            response = "Could you Please provide your email address."
            say(response)
            gmail_user, _ = takecommand()
            gmail_user = gmail_user.replace(" ", "").replace("at", "@").lower()
            response ="And your email password."
            say(response)
            gmail_password, _ = takecommand()
            try:
                send_email(subject, message, to, gmail_user, gmail_password)
                print("send_email function executed without raising an exception")
                response = "Your email has been sent successfully!"
                return response
            except Exception as e:
                print(f"Exception occurred in email_command function: {str(e)}")
                if attempt == 0:
                    response = "I'm sorry, but I couldn't send the email. Would you like to try again?"
                    retry, _ = takecommand()
                    if 'no' in retry.lower():
                        return response
                else:
                    response = "I'm sorry, but I couldn't send the email. Please check your details and try again later."
                    return response
        else:
            response = "Okay, let's try again. Please tell me the recipient's email address."
            to, _ = takecommand()
            to = to.replace(" ", "").replace("at", "@").lower()
    return response

def open_application(app_name):
    try:
        # Mapping app names to their system names
        apps = {
            "microsoft store": "ms-windows-store:",
            "microsoft edge": "microsoft-edge:",
            "outlook": "outlook.exe",
            "word": "winword.exe",
            "excel": "excel.exe",
            "notepad": "notepad.exe",
            "calculator": "calc.exe",
            "chrome": "chrome.exe",
            "powerpoint": "powerpnt.exe",
            "onenote": "onenote.exe",
            "spotify": "Spotify.exe",
            "settings": "ms-settings:",
            "whatsapp": "whatsapp:",
            "file explorer": "explorer",
            "camera": "microsoft.windows.camera:",
        }
        if app_name.lower() not in apps:
            response = f"Hmm, I couldn't find an application named {app_name}. Could you please confirm the name or try another application?"
            say(response)
        os.system(f'start {apps[app_name.lower()]}')
        print(f'{app_name} opened successfully')
    except Exception as e:
        response ="I'm sorry, but an error occurred while trying to open the application. Please try again later."
        print(f'Error occurred: {str(e)}')
        say(response)

def close_application(app_name):
    try:
        # Mapping app names to their process names
        processes = {
            "microsoft store": "ms-windows-store:",
            "microsoft edge": "microsoft-edge:",
            "outlook": "outlook.exe",
            "word": "winword.exe",
            "excel": "excel.exe",
            "notepad": "notepad.exe",
            "calculator": "calc.exe",
            "chrome": "chrome.exe",
            "powerpoint": "powerpnt.exe",
            "onenote": "onenote.exe",
            "spotify": "Spotify.exe",
            "settings": "ms-settings:",
            "whatsapp": "whatsApp:",
            "file explorer": "explorer",
            "camera": "microsoft.windows.camera:",
        }
        if app_name.lower() not in processes:
            response = f"Hmm, I couldn't find an application named {app_name}. Could you please confirm the name or try another application?"
            say(response)
        else:
            os.system(f'taskkill /IM {processes[app_name.lower()]} /F')
            print(f'{app_name} closed successfully')
    except Exception as e:
        response = "I'm sorry, but an error occurred while trying to close the application. Please try again later."
        print(f'Error occurred: {str(e)}')
        say(response)

def open_google_maps(source, destination):
    try:
        google_maps_url = f"https://www.google.com/maps/dir/{source}/{destination}"
        webbrowser.open(google_maps_url)
        response = f"I have opened Google Maps with directions from{source} to {destination}."
        return response
    except Exception as e:
        response = "I'm sorry, but an error occured while trying to open Google Maps. Please try again later."
        print(f"Error: {str(e)}")
        return response


def get_user_location():
    for attempt in range(3):
        response = "Could you please provide me your starting location?"
        say(response)
        source, _ = takecommand()
        if not source:
            response = "I'm sorry, I didn't catch that. Could you please repeat?"
            say(response)
            continue
        # Extracting the last one or two phrase in the user's response
        source_words =source.split()
        source = ' '.join(source.split()[-2:]) if len(source_words) > 1 else source_words[-1]

        response = f"You said the starting location is {source}. Is that correct?"
        say(response)
        confirmation, _ = takecommand()
        confirmation = confirmation.lower()
        if 'yes' in confirmation or 'yeah' in confirmation:
            break
        else:
            response = "Okay, let's try again."
            say(response)
            continue

    for attempt in range(3):
        response = "Now, could you please tell me your destination?"
        say(response)
        destination, _ = takecommand()
        if not destination:
            response = "I'm sorry, I didn't catch that. Could you please repeat?"
            say(response)
            continue
        destination_words = destination.split()
        destination = ' '.join(destination.split()[-2:]) if len(destination_words) > 1 else destination_words[-1]

        response = f"You said the destination is {destination}. Is that correct?"
        say(response)
        confirmation, _ = takecommand()
        confirmation = confirmation.lower()
        if 'yes' in confirmation or 'yeah' in confirmation:
            break
        else:
            response = "Okay, let's try again."
            say(response)
            continue

    return source, destination


# Whatsapp Message Functionalities

def get_phone_number():
    response = "Please provide the recipient's phone number, starting with the country code"
    say(response)
    while True:
        phone_number, _ = takecommand()
        if confirm_input(f"You said {phone_number}. Is that correct?"):
            return phone_number

def get_message():
    response = "What message would you like to send?"
    say(response)
    while True:
        message, _ = takecommand()
        if confirm_input(f"You said: {message}. Is that correct?"):
            return message


def get_time():
    response = "At what time would you like to send the message? You can say it like '5:05 pm' or '17:05'."
    say(response)
    attempts = 0
    while attempts < 3:
        time_input, _ = takecommand()
        if confirm_input(f"You said {time_input}. Is that correct?"):
            try:
                # Clean up the input
                time_input = time_input.lower().strip()
                time_input = re.sub(r'[.,]', '', time_input)  # Remove periods and commas
                time_input = re.sub(r'\s+', ' ', time_input)  # Normalize spaces

                # Replace various forms of am/pm
                time_input = re.sub(r'\b(a\.?m?\.?|p\.?m?\.?)\b', lambda m: m.group(1)[0].upper() + 'M', time_input)

                # Try multiple time formats
                for fmt in ["%I:%M %p", "%H:%M", "%I %p", "%I%p"]:
                    try:
                        time_obj = datetime.strptime(time_input, fmt)
                        break
                    except ValueError:
                        continue
                else:
                    raise ValueError("No valid time format found")

                current_time = datetime.now()
                scheduled_time = current_time.replace(hour=time_obj.hour, minute=time_obj.minute, second=0,
                                                      microsecond=0)

                if scheduled_time <= current_time:
                    scheduled_time += timedelta(days=1)

                # Confirm the interpreted time
                if confirm_input(f"I understood that as {scheduled_time.strftime('%I:%M %p')}. Is that correct?"):
                    return scheduled_time.hour, scheduled_time.minute
                else:
                    response = "I apologize for the misunderstanding. Let's try again."
                    say(response)
            except ValueError as e:
                response = "I couldn't understand the time format. Please try again, saying it like '5:05 pm' or '17:05'."
                say(response)
        attempts += 1

    response = "I'm having trouble understanding the time. Let's try entering it manually."
    say(response)
    while True:
        response = "Please type the time in 24-hour format (HH:MM)."
        say(response)
        time_input = input("Enter time (HH:MM): ")
        try:
            time_obj = datetime.strptime(time_input, "%H:%M")
            current_time = datetime.now()
            scheduled_time = current_time.replace(hour=time_obj.hour, minute=time_obj.minute, second=0, microsecond=0)
            if scheduled_time <= current_time:
                scheduled_time += timedelta(days=1)
            return scheduled_time.hour, scheduled_time.minute
        except ValueError:
            response = "Invalid time format. Please try again."
            say(response)
def send_whatsapp_message():
    try:
        response = "Sure, I would be happy helping with that."
        say(response)

        phone_number = get_phone_number()
        message = get_message()
        time_hour, time_minute = get_time()

        response = f"Scheduling your message to {phone_number} at {time_hour:02d}:{time_minute:02d}."
        say(response)


        pywhatkit.sendwhatmsg(phone_no=phone_number, message=message, time_hour=time_hour, time_minute=time_minute)
        say("Waiting for WhatsApp web to open.")
        time.sleep(40)  # You might want to adjust this delay based on your internet speed
        pyautogui.click()  # Changed from press('enter') to click() for better reliability
        pyautogui.press('enter')
        response = "Message sent successfully."
        say(response)

    except Exception as e:
        response = "An error occurred while sending the message: {str(e)}"
        say(response)

def confirm_input(prompt):
    say(prompt)
    while True:
        confirmation, _ = takecommand()
        confirmation = confirmation.lower()
        if any(word in confirmation for word in ["yes", "yeah", "correct", "right"]):
            return True
        elif any(word in confirmation for word in ["no", "not", "incorrect", "wrong"]):
            return False
        else:
            response = "I didn't understand. Please say 'yes' or 'no'."
            say(response)

# Function to capture picture automatically.


#Endpoint for voice input and responses
@app.route('/toggle-listening', methods=['POST'])
def toggle_listening():
    global listening
    if not listening:
        # Start's listening
        listening = True
        with sr.Microphone() as source:
            print("Listening...")
            audio = recognizer.listen(source)
            try:
                query = recognizer.recognize_google(audio)
                print(f"Recognized: {query}")
                handle_input(query, is_voice=True)
            except sr.UnknownValueError:
                print("could not understand")
            except sr.RequestError as e:
                print(f"Could not request results from Google Speech Recognition service; {e}")
    else:
        # Stop listening
        listening = False
        return jsonify({'message': 'Stopped listening', 'listening': listening})

#Endpoint Text input
@app.route('/process-text', methods=['POST'])
def process_text_route():
    text = request.form['text']
    processed_text = process_text(text)
    response = handle_input(text)
    return response


#Handling both voice input text input
def handle_input(query, is_voice=False):
    query = query.lower()
    greetings = ['hey sam', 'hello sam', 'hi sam']
    farewells = ['thank you', 'thanks', 'ok thank you', 'okay thanks', 'that\'s all', 'bye']

    if any(greeting in query for greeting in greetings):
        response = "Hey there, how's it going. How can I assist you today."

    elif any(farewell in query for farewell in farewells):
        response = "Great! if you need anything else in the future, feel free to reach out. Have a wonderful day!"
        listening = False
        return response

    elif "weather" in query:
        api_key = "91029bee01cd2f649f78078554268fa8"
        city_name = query.split("in ")[1]  # Extracting the city name from the user's query
        weather_info = get_weather(city_name, api_key)
        if isinstance(weather_info, tuple):
            response = f"Right now in {city_name}, it's {weather_info[0]:.2f} " \
                       f"degrees Celsius, with a wind speed of {weather_info[3]} km/h. " \
                       f"The humidity is at {weather_info[2]}%, It's {weather_info[4]} outside."

        else:
            response = "I'm sorry, I couldn't fetch the weather data right now."

    elif "news" in query:
        api_key = "78741a5134de4b28887d8531ef312fb5"
        if "about" in query:
            topic = query.split("about ")[1]
        else:
            topic = 'latest'
        news = get_news(api_key, topic)
        for article in news:
            response = f"Sure. Here's an interesting news story titled. {article['title']}. "\
                       f"Here's what it's about. {article['content']}. "\
                       f"If you're interested in exploring this further, you can read the complete article at the given URL."
            break
        else:
            response = "I couldn’t find any news articles at the moment."
            say(response)

    elif "send an email" in query or "send a email" in query:
        email_command()

    elif any(f"open {site[0]}".lower() in query.lower() for site in
             [["youtube", "https://youtube.com"],
              ["google", "https://google.com"],
              ["wikipedia", "https://wikipedia.com"],
              ["spotify", "https://open.spotify.com"],
              ["Amazon", "https://amazon.com"],
              ["GitHub", "https://github.com"]]
             ):
        sites = [["youtube", "https://youtube.com"], ["google", "https://google.com"],
                 ["wikipedia", "https://wikipedia.com"], ["spotify", "https://open.spotify.com"],
                 ["Amazon", "https://amazon.com"],["GitHub", "https://github.com"]]
        for site in sites:
            if f"open {site[0]}".lower() in query.lower():
                response = f"Sure, I'm navigating to {site[0]} for you."
                webbrowser.open(site[1])

    elif "open" in query:
        app_name = query.split("open", 1)[1].strip()  # Extracting the app name from the user's query
        if app_name.endswith(' for me'):
            app_name = app_name[:-7]

            response = f"Sure, I will open {app_name} for you."
            open_application(app_name)

    elif "close" in query:
        app_name = query.split("close", 1)[1].strip()  # Extracting the app name from the user's query
        if app_name.endswith(' for me'):
            app_name = app_name[:-7]
        response = f"Sure, I will close {app_name} for you."
        close_application(app_name)

    elif "time" in query:
        current_time = datetime.datetime.now().strftime("%I:%M %p")
        response = f"Currently, it's {current_time}."

    elif "directions" in query or "location" in query:
        response = "Sure, I'll help you with that."
        say(response)
        source, destination = get_user_location()
        if source and destination:
            response = f"Alright, let me find the best route from {source} to {destination}"
            maps_response = open_google_maps(source, destination)
            response += " " + maps_response
        else:
            response = "I'm sorry, but I couldn't get the locations. Could you please try again?"

    elif "send a whatsapp message" in query:
        send_whatsapp_message()
        response = "Done! Your WhatsApp message is on its way. Let me know if you want to send another one."

    else:
        try:
            response = chat_session.send_message(query)

            if response.text.strip():
                response = response.text
            else:
                response = "I'm sorry, I didn't understand that could you please repeat or try a different request"
        except Exception as e:
            response = "An error occured while processing your request. Please try again later."
            print(f"Error: {str(e)}")

    if is_voice:
        say(response)
    else:
        return response

if __name__ == '__main__':
    app.run(debug=True)


# whatsapp functionality ::   store text in response and call it using say()