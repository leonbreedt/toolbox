# Sparkle Integration Summary

Sparkle has been successfully integrated into Toolbox. This document summarizes what was done and what you need to do next.

## What Was Done

### 1. Code Integration
- ✅ Added Sparkle 2.8.1 as a Swift Package dependency
- ✅ Configured SPUStandardUpdaterController in AppDelegate
- ✅ Added "Check for Updates…" menu item to status bar menu
- ✅ Created entitlements file with network access permission
- ✅ Configured Info.plist with SUFeedURL pointing to GitHub Pages

### 2. GitHub Pages Setup
- ✅ Created `docs/` directory for GitHub Pages
- ✅ Created initial `appcast.xml` feed file
- ✅ Created `index.html` for the GitHub Pages site

### 3. Build Workflow Updates
- ✅ Added Sparkle tools download step
- ✅ Added appcast generation and signing
- ✅ Added GitHub Pages deployment
- ✅ Integrated with existing notarization workflow

### 4. Documentation
- ✅ Created comprehensive release process guide
- ✅ Created quick reference guide
- ✅ Updated CHANGELOG.md

## What You Need to Do

### Required: One-Time Setup

#### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** → **Pages**
3. Under **Source**, select **Deploy from a branch**
4. Set **Branch** to `gh-pages`
5. Set folder to `/ (root)`
6. Click **Save**

#### 2. Generate Sparkle EdDSA Keys

You have two options:

**Option A: Generate Locally (Recommended)**

```bash
# Download Sparkle tools
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz -o sparkle.tar.xz
tar -xf sparkle.tar.xz

# Generate keys
./bin/generate_keys
```

This outputs two lines:
1. **Private key** (starts with "PRIVATE KEY:")
2. **Public key** (starts with "PUBLIC KEY:")

**Option B: Let GitHub Actions Generate**

The workflow will generate keys on the first release, but you'll need to:
1. Check the workflow logs
2. Copy the private key from the output
3. Save it as a GitHub secret

#### 3. Add Public Key to Xcode

Open your Xcode project and add the public key:

1. Open `Toolbox.xcodeproj` in Xcode
2. Select the **Toolbox** target
3. Go to **Build Settings** tab
4. Click the **+** button and select **Add User-Defined Setting**
5. Name it: `INFOPLIST_KEY_SUPublicEDKey`
6. Set the value to your public key (without "PUBLIC KEY:" prefix)

Alternatively, you can add it directly to the project.pbxproj:

```
INFOPLIST_KEY_SUPublicEDKey = "YOUR_PUBLIC_KEY_HERE";
```

#### 4. Add Private Key to GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SPARKLE_EDDSA_KEY`
5. Value: Your **entire private key line** from generate_keys (including "PRIVATE KEY:" prefix)
6. Click **Add secret**

### Testing the Integration

#### Test Locally (Optional)

Build and run the app locally:

```bash
xcodebuild -project Toolbox.xcodeproj \
  -scheme Toolbox \
  -configuration Debug \
  build
```

Run the app and check:
1. The app launches successfully
2. The status bar menu shows "Check for Updates…"
3. No crashes related to Sparkle

#### Test First Release

Create your first release:

```bash
# Update version to 1.0.4 in Xcode

# Update CHANGELOG.md (already done)

# Commit changes
git add .
git commit -m "build: bump version to 1.0.4"
git push origin main

# Create and push tag
git tag -a v1.0.4 -m "Release version 1.0.4"
git push origin v1.0.4
```

Monitor the GitHub Actions workflow:
1. Go to **Actions** tab
2. Watch the "Build macOS DMG" workflow
3. Check that all steps complete successfully

Verify the release:
1. Check GitHub Releases page for the DMG
2. Visit `https://YOUR_USERNAME.github.io/toolbox/appcast.xml` (replace YOUR_USERNAME)
3. Verify the appcast XML contains your release

## File Changes Summary

### New Files
- `Toolbox/Toolbox.entitlements` - App entitlements with network access
- `docs/appcast.xml` - Sparkle appcast feed
- `docs/index.html` - GitHub Pages landing page
- `.github/RELEASE_PROCESS.md` - Comprehensive release documentation
- `.github/RELEASE_QUICK_REFERENCE.md` - Quick reference guide
- `.github/SPARKLE_SETUP_SUMMARY.md` - This file

### Modified Files
- `Toolbox.xcodeproj/project.pbxproj` - Added Sparkle package, entitlements, SUFeedURL
- `Toolbox/App/AppDelegate.swift` - Integrated SPUStandardUpdaterController
- `Toolbox/App/StatusItemController.swift` - Added "Check for Updates" menu item
- `.github/workflows/build.yml` - Added Sparkle signing and appcast generation
- `CHANGELOG.md` - Added Sparkle update entry

## How Updates Work

1. **User launches app** → Sparkle automatically checks for updates in the background
2. **Update available** → User sees notification with option to install
3. **User clicks update** → DMG downloads, verifies signature, installs automatically
4. **App relaunches** → User is now on the latest version

The update check happens:
- When the app launches (after a delay)
- When user clicks "Check for Updates…" in the menu
- Periodically in the background (configurable)

## Security

All updates are secured with:
- **Apple Code Signing** - DMG and app are signed with Developer ID
- **Apple Notarization** - DMG is notarized by Apple
- **Sparkle EdDSA Signature** - Update package is cryptographically signed

This ensures users only install authentic updates from you.

## Troubleshooting

### "Check for Updates" doesn't work
- Verify the public key is correctly set in Xcode
- Check that network entitlements are enabled
- Look for errors in Console.app while running

### Workflow fails
- Check all GitHub secrets are set correctly
- Verify code signing certificate is valid
- Check workflow logs for specific errors

### Appcast not updating
- Ensure GitHub Pages is enabled
- Check that gh-pages branch exists
- Verify peaceiris/actions-gh-pages action completed

## Next Steps

1. Complete the one-time setup steps above
2. Test building the project locally
3. Create your first release (v1.0.4)
4. Test that updates work
5. Document any additional steps for your specific setup

## Questions?

Refer to:
- [RELEASE_PROCESS.md](.github/RELEASE_PROCESS.md) - Complete release guide
- [RELEASE_QUICK_REFERENCE.md](.github/RELEASE_QUICK_REFERENCE.md) - Quick reference
- [Sparkle Documentation](https://sparkle-project.org/documentation/)

## Repository URL

**Important:** The appcast URL in the Xcode project assumes your repository is at:
`https://github.com/leonbreedt/toolbox`

If this is incorrect, update the `INFOPLIST_KEY_SUFeedURL` in Xcode build settings:
```
INFOPLIST_KEY_SUFeedURL = "https://YOUR_USERNAME.github.io/REPO_NAME/appcast.xml";
```
