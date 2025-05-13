[Better Webhooks](https://splunkbase.splunk.com/app/7450)

`Bot Token`: ######### (replace with your actual token from BotFather).

`Chat ID`: -######## (the ID of the group or chat, including the - for groups).

URL: Use the Telegram API endpoint without query parameters 
```
https://api.telegram.org/bot<your-bot-token>/sendMessage
```
Body Format:
```
{
  "chat_id": "-########",
  "text": "Alert from Splunk: $result.*$"
}
```
