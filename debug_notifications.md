# Notification Debugging Guide

## Current Status
✅ **Instant notifications work**  
❌ **Scheduled notifications don't work**

## Updated Features
I've enhanced your notification system with:

1. **Better Debugging**: Added detailed logging to help identify the exact issue
2. **Exact Alarm Permissions**: Added support for Android 12+ exact alarm permissions
3. **Permission Status**: Shows detailed permission information
4. **Enhanced Error Handling**: Better error messages and debugging info

## How to Debug Scheduled Notifications

### Step 1: Use the Test Screen
1. Open the app → Hamburger menu → "Notification Test"
2. Check the "Notification System Status" section for any issues
3. Try scheduling a notification for 5-10 seconds in the future
4. Watch the "Test Results Log" for detailed debug information

### Step 2: Look for These Common Issues

#### A) Permission Issues
- **Basic Notifications**: Should show as granted
- **Exact Alarms**: On Android 12+ devices, this might need manual approval
- Check the debug log for permission status

#### B) Timezone Issues
- The debug log will show timezone information
- Look for "TZDateTime" and "Local timezone" entries

#### C) Past Time Issues
- The system will reject notifications scheduled for the past
- Check if the calculated time is in the future

### Step 3: Android Settings Check
If permissions show as granted but notifications still don't work:

1. **Device Settings** → **Apps** → **Dosifi** → **Notifications**
   - Enable "Allow notifications"
   - Check all notification categories are enabled

2. **Device Settings** → **Apps** → **Special access** → **Alarms & reminders**
   - Find your app and enable it (Android 12+)

3. **Device Settings** → **Battery** → **Battery optimization**
   - Find your app and set to "Don't optimize"

### Step 4: Debug Output Analysis
When you tap "Scheduled", look for these log entries:

```
✅ Good signs:
- "NotificationService initialized"
- "Permission check: {notifications: true, exactAlarms: true}"
- "Successfully scheduled notification"
- "Found X pending notifications" (where X > 0)

❌ Problem signs:
- "Cannot schedule notification for past time"
- "Error scheduling notification"
- "Permission check: {notifications: false...}"
- "Exact alarm permission request failed"
```

### Step 5: Test Different Time Intervals
Try scheduling notifications at:
- 5 seconds (immediate test)
- 1 minute (short test)  
- 5 minutes (longer test)

### Step 6: Check Pending Notifications
The "Pending Notifications" section should show your scheduled notifications. If it's empty after scheduling, the notification wasn't actually scheduled.

## Common Solutions

### If permissions are denied:
1. Manually grant notification permissions in Android settings
2. For Android 12+: Grant "Alarms & reminders" permission
3. Disable battery optimization for the app

### If timezone is wrong:
1. The app will try to use America/New_York timezone
2. You can modify `lib/services/notification_service.dart` line 25 to use your local timezone
3. Available timezones: 'America/Los_Angeles', 'Europe/London', 'Asia/Tokyo', etc.

### If notifications are scheduled but don't appear:
1. Check device's "Do Not Disturb" mode
2. Verify notification channel settings in Android settings
3. Try rebooting the device (Android sometimes needs this)

## Next Steps

1. **Install and test** the updated APK
2. **Use the test screen** to see the detailed debug output
3. **Report back** with the debug log entries when you try to schedule a notification
4. If needed, we can add more specific debugging or try alternative scheduling approaches

The enhanced debugging will help us identify exactly where the issue is occurring!
