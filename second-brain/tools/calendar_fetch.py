#!/usr/bin/env python3
"""
calendar_fetch.py
Fetches today's Google Calendar events and prints them for morning-brief.sh.
First run opens a browser for OAuth authorization and saves token.json.
Subsequent runs use the saved token (auto-refreshed).
"""

import datetime
import os
import sys

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
CREDENTIALS_FILE = os.path.join(TOOLS_DIR, "credentials.json")
TOKEN_FILE = os.path.join(TOOLS_DIR, "token.json")


def get_credentials():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())
    return creds


def fetch_today_events(creds):
    service = build("calendar", "v3", credentials=creds)

    tz_offset = datetime.timezone(datetime.timedelta(hours=-4))  # EDT
    now = datetime.datetime.now(tz_offset)
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=0)

    events_result = service.events().list(
        calendarId="primary",
        timeMin=start_of_day.isoformat(),
        timeMax=end_of_day.isoformat(),
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    return events_result.get("items", [])


def format_events(events):
    if not events:
        return "No events scheduled today."

    lines = []
    for event in events:
        start = event["start"].get("dateTime", event["start"].get("date", ""))
        if "T" in start:
            dt = datetime.datetime.fromisoformat(start)
            time_str = dt.strftime("%-I:%M %p")
        else:
            time_str = "All day"
        summary = event.get("summary", "(no title)")
        lines.append(f"- {time_str}: {summary}")

    return "\n".join(lines)


if __name__ == "__main__":
    try:
        creds = get_credentials()
        events = fetch_today_events(creds)
        print(format_events(events))
    except Exception as e:
        print(f"(Calendar fetch failed: {e})")
        sys.exit(0)  # Exit cleanly so morning-brief.sh still runs
