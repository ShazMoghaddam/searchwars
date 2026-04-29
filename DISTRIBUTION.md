# SearchWars — Distribution Guide

---

## 📱 1. Build an Android APK

### One-time setup (if you haven't already)

```bash
# Generate a signing keystore (run once, keep the .jks file safe forever)
keytool -genkey -v \
  -keystore ~/searchwars-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias searchwars \
  -storepass YOUR_PASSWORD \
  -keypass YOUR_PASSWORD \
  -dname "CN=Shaz, OU=SearchWars, O=SearchWars, L=London, ST=England, C=GB"
```

### Create key.properties

Create `android/key.properties` (never commit this to git):

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=searchwars
storeFile=/Users/shaz/searchwars-release-key.jks
```

### Update android/app/build.gradle

Add above `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.withReader('UTF-8') { reader ->
        keystoreProperties.load(reader)
    }
}
```

Update `signingConfigs` inside `android {}`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

### Build commands

```bash
cd ~/Downloads/higher_lower

# Debug APK (for testing on your own device)
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

# Release APK (to share via WhatsApp/AirDrop)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# App Bundle (required for Play Store submission)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Install on Android phone

```bash
# Via USB (phone must have USB debugging on)
flutter install

# Or copy APK to phone and open it
# Settings → Install unknown apps → allow
```

### Share via WhatsApp/AirDrop

```bash
# Find the APK
open build/app/outputs/flutter-apk/
# Then drag app-release.apk into WhatsApp/Messages
```

---

## 🌐 2. Progressive Web App (PWA)

The web build is already configured as a PWA with:
- ✅ `web/manifest.json` — app name, colours, icons
- ✅ `web/sw.js` — service worker for offline play
- ✅ `web/index.html` — iOS install hint, Android install prompt

### Build and serve

```bash
# Build for web
flutter build web --release

# Serve locally to test PWA
cd build/web
python3 -m http.server 8080
# Open http://localhost:8080 in Chrome
```

### Host it (free options)

**Netlify (recommended — 30 seconds):**
```bash
# Install netlify CLI
npm install -g netlify-cli

# Build and deploy
flutter build web --release
netlify deploy --prod --dir=build/web
# You get a URL like: https://searchwars.netlify.app
```

**GitHub Pages:**
```bash
flutter build web --release --base-href /searchwars/
# Push build/web to gh-pages branch
```

**Firebase Hosting:**
```bash
npm install -g firebase-tools
firebase login
firebase init hosting  # select build/web as public dir
firebase deploy
```

### iPhone install instructions (share with users)

1. Open the URL in **Safari** (not Chrome)
2. Tap the **Share** button (box with arrow)
3. Tap **"Add to Home Screen"**
4. Tap **"Add"**
5. SearchWars icon appears on home screen — works offline!

---

## 🏪 3. Google Play Store Submission

### Required accounts
- Google Play Developer account: $25 one-time fee at play.google.com/console
- Takes 1-2 days for account approval

### Complete store listing (copy-paste ready)

**App name:** SearchWars

**Short description (80 chars):**
```
Which gets more Google searches? The ultimate trivia game! 🔥
```

**Full description (4000 chars max):**
```
🎮 SEARCHWARS — The Google Searches Trivia Game

Can you guess which gets searched more on Google? 
McDonald's or KFC? Taylor Swift or Beyoncé? 
Ferrari or Lamborghini? Test your knowledge across 
3,187 questions in 11 categories!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 HOW TO PLAY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You see two things. You guess which one gets more 
monthly Google searches. Simple to learn, impossible 
to master!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 3,187 QUESTIONS ACROSS 11 CATEGORIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏅 Sports — F1, Football, Basketball, Tennis, Boxing & More
⭐ Celebrity — Actors, Musicians, Influencers
🎬 TV & Music — Shows, Films, Artists, Genres  
💻 Tech — Phones, Apps, Companies, AI
🎮 Gaming — Games, Consoles, Streamers, Esports
🍔 Food & Drink — Restaurants, Cuisines, Trends
🌍 Geography — Countries, Cities, Landmarks
🏛️ History — Events, Figures, Wars, Empires
🗳️ Politics — Leaders, Parties, Events
🔬 Science — Space, Animals, Medicine, Climate
🚗 Automotive — Cars, Brands, Racing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌟 FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗓️ DAILY CHALLENGE — 10 new questions every day, 
   same for everyone worldwide. Build your streak!

🌍 GLOBAL LEADERBOARD — Compete against players 
   worldwide. Weekly & all-time rankings with 
   country flags and verified badges for top scorers.

👥 2-PLAYER MODE — Pass the phone! Take turns 
   answering. Perfect for family game nights.

🔥 STREAK SYSTEM — Chain correct answers for 
   bonus excitement. Can you hit 20 in a row?

📊 STATS TRACKING — See your accuracy per 
   category, total questions answered, and 
   personal bests with animated charts.

🏆 PERSONAL BESTS — Every category tracks your 
   highest score. Always something to beat.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎮 GAME MODES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Classic — 3 lives, play until you run out
• Daily Challenge — 10 questions, one attempt per day
• 2-Player — Head-to-head on one device

No internet required for gameplay — play anywhere, anytime!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🇬🇧 BRITISH-FRIENDLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Questions include UK-specific content: Greggs vs 
Nando's, Coronation Street vs EastEnders, 
Glastonbury, Premier League, and much more.

Download and see how well you really know the internet!
```

**Category:** Trivia

**Tags:** trivia, quiz, google, search, pub quiz, general knowledge

**Content rating:** Everyone (E)

**Privacy policy URL:** You need a simple one — use https://www.termsfeed.com to generate free

---

## 📤 4. Share Score Format

The share button generates text like:

**Regular game:**
```
🔥 SearchWars — Sports

Shaz scored 14 points!
██████████████░░░░░░ 14

Can you beat them? 🔥
Play at: YOUR-APP-URL.netlify.app

#SearchWars #HigherOrLower
```

**Daily Challenge (Wordle-style):**
```
🗓️ SearchWars Daily Challenge — 2026-04-28

Shaz: 8/10
🟩🟩🟩🟩🟩🟩🟩🟩🟥🟥

Same 10 questions for everyone today.
Can you do better? 🔥
Play at: YOUR-APP-URL.netlify.app

#SearchWars #DailyChallenge
```

---

## 💰 5. AdMob Rewarded Ads Setup

### Create AdMob account (free)

1. Go to **admob.google.com** → sign in with Google
2. **Add app** → Android → enter "SearchWars"
3. Copy the **App ID** (looks like `ca-app-pub-XXXXX~XXXXX`)
4. Go to **Ad Units** → Create ad unit → **Rewarded** → name it "Extra Life"
5. Copy the **Ad Unit ID**

### Add to your app

In `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR-APP-ID"/>
```

In `lib/services/ad_service.dart`:
```dart
static const String androidAppId     = 'ca-app-pub-YOUR-APP-ID';
static const String rewardedAdUnitId = 'ca-app-pub-YOUR-REWARDED-UNIT-ID';
```

Then at the bottom of the file:
```dart
const bool kAdsEnabled = true; // ← change false to true
```

### Revenue estimate

| DAU  | Rewarded fills | RPM    | Monthly |
|------|----------------|--------|---------|
| 100  | ~20/day        | £8     | ~£5     |
| 1000 | ~200/day       | £8     | ~£50    |
| 10k  | ~2000/day      | £8     | ~£500   |

---

## 🔔 6. Push Notifications (Daily Challenge reminder)

Requires Firebase Cloud Messaging (FCM). See `README_NOTIFICATIONS.md` for full setup.
Short version: add `firebase_messaging` package, request permission on app launch,
send notifications from Firebase Console → Cloud Messaging → "Send your first message".

Target: "Daily challenge is ready! 🗓️ Can you beat yesterday's score?"
Schedule: Daily at 8am in user's timezone.
