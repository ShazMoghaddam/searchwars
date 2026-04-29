# SearchWars 🔼🔽
### Which gets more Google searches?

A mobile game inspired by higherlowergame.com. Players see two items and guess which one gets more monthly Google searches.

---

## 📱 Features

- **3,187 questions** across 11 categories
- **3 lives** — one wrong answer costs a heart
- **High scores** saved per category with SharedPreferences
- **Subcategory navigation** for Sports (F1, Football, Basketball, etc.)
- **Shuffle mode** — random mix of all categories
- **Smooth animations** — card reveal, slide transitions, flash feedback
- **Portrait-locked** — clean mobile-first layout
- **Dark theme** — vibrant category colours on dark background

---

## 🗂️ Categories

| Category | Questions |
|---|---|
| 🏅 Sports (F1, Football, Basketball, Tennis, Boxing/MMA) | 937 |
| ⭐ Celebrity | 260 |
| 🎬 TV, Film & Music | 250 |
| 💻 Tech | 240 |
| 🚗 Automotive | 225 |
| 🎮 Gaming | 225 |
| 🌍 Geography | 225 |
| 🏛️ History | 225 |
| 🍔 Food & Drink | 200 |
| 🗳️ Politics | 200 |
| 🔬 Science & Nature | 200 |
| **Total** | **3,187** |

---

## 🛠️ Setup

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin
- Android SDK (API 21+)

### Install

```bash
git clone <your-repo>
cd higher_lower
flutter pub get
flutter run
```

### Build release APK

```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# AAB at: build/app/outputs/bundle/release/app-release.aab
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point, loads dataset
├── theme.dart                   # Colours, category colours
├── models/
│   └── game_models.dart         # GameItem, GamePair, Category models
├── data/
│   └── dataset_loader.dart      # JSON loader + category/filter logic
├── services/
│   └── score_service.dart       # High score persistence (SharedPreferences)
└── screens/
    ├── home_screen.dart          # Category grid + subcategory bottom sheet
    ├── game_screen.dart          # Main game loop with animations
    └── game_over_screen.dart     # Result screen with score + replay

assets/
└── data/
    └── dataset.json             # 3,187 question pairs (~0.91 MB)
```

---

## 🎮 Game Flow

```
Home Screen
  └─► Category selected
        └─► [Sports] → Subcategory sheet → Pick sub-topic
        └─► [Other] → Game Screen directly
              └─► Show Card A (revealed) + Card B (hidden)
              └─► Player taps HIGHER or LOWER
              └─► Reveal Card B volume
              └─► Correct → Card B slides up, new card appears
              └─► Wrong → ❤️ lost, continue
              └─► 0 lives → Game Over Screen
                    └─► Show score, best, emoji
                    └─► Play Again / Choose Category
```

---

## 📦 Dependencies

```yaml
shared_preferences: ^2.2.2   # High score storage
google_fonts: ^6.1.0          # Typography (optional)
flutter_animate: ^4.3.0       # Animation helpers (optional)
audioplayers: ^5.2.1          # Sound effects (optional)
```

---

## 🚀 Play Store Submission Checklist

- [ ] Set `applicationId` in `android/app/build.gradle`
- [ ] Generate release keystore: `keytool -genkey -v -keystore upload-keystore.jks`
- [ ] Create `android/key.properties` with keystore config
- [ ] Update `signingConfig` in build.gradle to use keystore
- [ ] Add app icons (replace mipmap folders)
- [ ] Create store listing screenshots (use `flutter screenshot`)
- [ ] Set min SDK 21, target SDK 34
- [ ] Run `flutter build appbundle --release`
- [ ] Upload AAB to Play Console

---

## 🔧 Customisation

### Add questions
Edit `assets/data/dataset.json` — each pair follows this format:
```json
{
  "id": "unique_id",
  "category": "sports",
  "subcategory": "football",
  "subgroup": "players_current",
  "itemA": { "name": "Lionel Messi", "searchVolume": 18000000 },
  "itemB": { "name": "Cristiano Ronaldo", "searchVolume": 20000000 }
}
```

### Add AdMob
1. Add `google_mobile_ads: ^4.0.0` to pubspec.yaml
2. Add App ID to AndroidManifest.xml meta-data
3. Show banner in `HomeScreen` bottom, interstitial in `GameOverScreen`

### Change theme
Edit `lib/theme.dart` — modify `categoryColors` map or `AppColors` constants.

---

## 📄 Licence
https://github.com/ShazMoghaddam/searchwars/blob/main/LICENSE
