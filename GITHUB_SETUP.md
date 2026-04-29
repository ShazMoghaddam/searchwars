# SearchWars — GitHub Setup Guide

---

## 1. Create the repository

```bash
cd ~/Downloads/higher_lower   # or wherever your project lives

git init
git add .
git commit -m "Initial commit — SearchWars v1.0.0"
```

Go to **github.com → New repository**:
- Name: `searchwars`
- Visibility: **Private** (recommended — your dataset is your IP)
- Do NOT tick "Add README" — you already have one

```bash
git remote add origin https://github.com/YOUR_USERNAME/searchwars.git
git branch -M main
git push -u origin main
```

---

## 2. Verify .gitignore is working

Before pushing, confirm these sensitive files are NOT tracked:

```bash
# These should all return nothing (not tracked):
git status android/key.properties
git status *.jks

# If either shows up, stop and run:
git rm --cached android/key.properties
git rm --cached *.jks
git commit -m "Remove accidentally tracked secrets"
```

---

## 3. Store your keystore safely (outside the repo)

Your `.jks` keystore file must **never** go into the repo.
Back it up to at least two of these:

- iCloud Drive / Google Drive (in a folder called `searchwars-secrets/`)
- An encrypted external drive
- A password manager that supports file attachments (e.g. 1Password, Bitwarden)

If you lose this file you permanently lose the ability to update your Play Store app.

---

## 4. Protect the main branch

On GitHub → Settings → Branches → Add rule:
- Branch name: `main`
- ✅ Require a pull request before merging
- ✅ Require status checks to pass (once you add CI)

This prevents accidental force-pushes to your main branch.

---

## 5. Optional — Auto-deploy to Netlify on push

Connect Netlify to your GitHub repo for automatic web deploys:

1. Go to **netlify.com → Add new site → Import an existing project**
2. Pick your `searchwars` repo
3. Set build settings:
   - **Build command:** `flutter build web --release`
   - **Publish directory:** `build/web`
4. Add environment variable (if needed): none required for basic build

Netlify will now rebuild and deploy your web app every time you push to `main`.

For the Flutter build to work on Netlify, add a `netlify.toml` to your project root:

```toml
[build]
  command   = "flutter build web --release"
  publish   = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.22.0"   # pin to your local Flutter version

[[redirects]]
  from   = "/*"
  to     = "/index.html"
  status = 200
```

And a `runtime.txt` to specify the Flutter channel:
```
3.22.0
```

---

## 6. Useful git commands for ongoing development

```bash
# Start a new feature
git checkout -b feature/daily-challenge

# Save work in progress
git add .
git commit -m "WIP: daily challenge screen"

# Merge back to main when done
git checkout main
git merge feature/daily-challenge

# Tag a release
git tag -a v1.0.1 -m "Fix service worker cache"
git push origin v1.0.1

# Before every release build — sync sw.js cache version
./bump_version.sh
```

---

## 7. What to commit vs what NOT to commit

| File / folder              | Commit? | Why |
|----------------------------|---------|-----|
| `lib/`                     | ✅ Yes  | Your source code |
| `assets/data/dataset.json` | ✅ Yes  | Game data |
| `web/`                     | ✅ Yes  | PWA files |
| `pubspec.yaml`             | ✅ Yes  | Dependency list |
| `android/app/build.gradle` | ✅ Yes  | Build config (no secrets) |
| `build/`                   | ❌ No   | Build outputs — always generated |
| `android/key.properties`   | ❌ No   | Contains keystore password |
| `*.jks`                    | ❌ No   | The keystore itself |
| `.env`                     | ❌ No   | Any future API keys |
| `pubspec.lock`             | Optional | Commit for reproducible CI builds |
