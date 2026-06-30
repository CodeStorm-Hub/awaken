# Alarm Audio Asset

Place your alarm sound file here as `alarm.mp3`.

Requirements:
- Format: MP3 (or OGG for Android-only builds)
- Duration: 5–30 seconds (it will loop)
- Recommended: loud, attention-grabbing tone — this is an alarm

Free sources:
- freesound.org (search "alarm clock")
- mixkit.co/free-sound-effects/alarm

On Android, if `alarm.mp3` is not present, AlarmAudioService falls back to the
device's system alarm ringtone (content://settings/system/alarm_alert).
On iOS, a missing asset will cause silent alarm — ensure this file exists before
shipping to the App Store.
