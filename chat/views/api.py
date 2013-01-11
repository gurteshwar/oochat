from flask import Blueprint, request, g
import json
from chat.datastore import get_channel_users, get_recent_messages

api = Blueprint("api", __name__)

@api.route("/user_status/<path:channel>")
def user_status(channel):
  return json.dumps(get_channel_users(channel))

@api.route("/messages/<path:channel>")
def messages(channel):
  return json.dumps(get_recent_messages(channel))

@api.route("/whoami")
def whoami():
  user = {
    "email": g.user["email"],
    "name": g.user["name"],
    "gravatar": g.user["gravatar"],
    "channels": g.user["channels"],
    "username": g.user["email"].split("@")[0],
  }
  return json.dumps({ "user": user })
