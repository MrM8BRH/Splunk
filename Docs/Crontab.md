[Crontab Guru](https://crontab.guru/)

Crontab is a time-based job scheduling program used in Unix-like operating systems to schedule recurring tasks or jobs. The name "crontab" comes from "cron," the daemon (background process) that runs scheduled tasks, and "tab," which is short for "table" since the scheduling information is organized in tabular form.

With crontab, users can schedule scripts, commands, or programs to run at specified intervals or times, such as daily, weekly, monthly, or even at specific minutes within an hour. This makes it particularly useful for automating repetitive tasks, maintenance activities, or any operation that needs to be executed on a regular basis.

The crontab file follows a specific format.

```
# <Minute> <Hour> <Day of Month> <Month> <Day of Week> Command
```

Each line in the crontab file represents a scheduled task or command. Here's a breakdown of the different fields:
- Minute: Specifies the minute(s) at which the task should run. Valid values are 0 to 59.
- Hour: Specifies the hour(s) at which the task should run. Valid values are 0 to 23.
- Day of Month: Specifies the day(s) of the month when the task should run. Valid values are 1 to 31.
- Month: Specifies the month(s) when the task should run. Valid values are 1 to 12 or their corresponding names (e.g., Jan, Feb, etc.).
- Day of Week: Specifies the day(s) of the week when the task should run. Valid values are 0 to 7 or their corresponding names (0 or 7 represents Sunday).
- Command: The actual command or script to be executed at the specified time and date.

To schedule a task, you need to add a line to your crontab file following this format. Each field is separated by spaces or tabs, and you can use asterisks (*) to represent any value.

Remember to run the `crontab -e` command to edit the crontab file for the current user.
