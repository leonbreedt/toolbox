# Release Process

This document describes the complete release process for Toolbox, including automatic Sparkle updates.

## Overview

The release process is highly automated. When you create and push a version tag, GitHub Actions will:

1. Build and sign the app
2. Create and notarize a DMG
3. Generate a Sparkle-signed update
4. Update the appcast XML feed
5. Create a GitHub release
6. Deploy the appcast to GitHub Pages

Users with the app installed will automatically be notified of updates via Sparkle.

## Prerequisites

Before your first release, ensure you have:

1. All secrets configured in GitHub (see [SIGNING_SETUP.md](SIGNING_SETUP.md))
2. GitHub Pages enabled for the repository:
   - Go to **Settings** → **Pages**
   - Set **Source** to "Deploy from a branch"
   - Set **Branch** to `gh-pages` and folder to `/ (root)`
   - Click **Save**
3. Sparkle EdDSA key pair (will be generated automatically on first release)

## First Release Setup

### Step 1: Generate Sparkle EdDSA Key

On your first release, the workflow will generate an EdDSA key pair for signing updates. You need to save this key as a GitHub secret.

**Option A: Generate locally (recommended)**

```bash
# Download Sparkle tools
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz -o sparkle.tar.xz
tar -xf sparkle.tar.xz

# Generate key pair
./bin/generate_keys

# This outputs two lines:
# 1. Private key (save as SPARKLE_EDDSA_KEY secret)
# 2. Public key (add to Info.plist)
```

**Option B: Let the workflow generate it**

The workflow will generate keys automatically, but you must:
1. Check the workflow logs after the first release
2. Copy the generated private key
3. Add it as a GitHub secret named `SPARKLE_EDDSA_KEY`

### Step 2: Add the Public Key to Info.plist

The public key must be added to your app's Info.plist. Since we use `GENERATE_INFOPLIST_FILE = YES`, add it as a build setting:

1. Open Xcode
2. Select the Toolbox target
3. Go to **Build Settings**
4. Search for "Info.plist"
5. Add a new key: `INFOPLIST_KEY_SUPublicEDKey`
6. Set the value to your public key (from generate_keys output)

Alternatively, create an `Info.plist` file and add:
```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

### Step 3: Add GitHub Secret

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SPARKLE_EDDSA_KEY`
5. Value: Your private key from the generate_keys output
6. Click **Add secret**

## Creating a Release

### Step 1: Update Version Number

Update the version in Xcode:
```bash
# Option 1: Using Xcode
# Open Toolbox.xcodeproj
# Select target → General → Version (MARKETING_VERSION)
# Change from 1.0.3 to 1.0.4 (for example)

# Option 2: Using command line (if using xcconfig)
# Edit the appropriate config file
```

Or use `agvtool` (if CURRENT_PROJECT_VERSION is set):
```bash
agvtool new-marketing-version 1.0.4
```

### Step 2: Update CHANGELOG.md

Add a new entry to `CHANGELOG.md`:

```markdown
# CHANGELOG

## 1.0.4 (2025-12-10)

- Added automatic update checking via Sparkle
- Fixed bug in JWT decoder
- Improved error handling

## 1.0.3 (2025-12-09)
...
```

### Step 3: Commit Changes

```bash
git add .
git commit -m "build: bump version to 1.0.4"
git push origin main
```

### Step 4: Create and Push Tag

```bash
# Create an annotated tag
git tag -a v1.0.4 -m "Release version 1.0.4"

# Push the tag to trigger the release workflow
git push origin v1.0.4
```

### Step 5: Monitor the Workflow

1. Go to the **Actions** tab on GitHub
2. Watch the "Build macOS DMG" workflow run
3. Ensure all steps complete successfully

### Step 6: Verify the Release

After the workflow completes:

1. **GitHub Release**: Check that a release was created at `https://github.com/YOUR_USERNAME/toolbox/releases`
2. **Appcast**: Verify the appcast was updated at `https://YOUR_USERNAME.github.io/toolbox/appcast.xml`
3. **Download**: Test downloading the DMG from the release
4. **Updates**: Launch an older version of the app and verify it detects the update

## What Happens Automatically

When you push a version tag (e.g., `v1.0.4`), the workflow:

1. **Builds** the app in Release configuration
2. **Signs** the app with your Developer ID
3. **Creates** a DMG disk image
4. **Signs** the DMG
5. **Notarizes** the DMG with Apple
6. **Staples** the notarization ticket to the DMG
7. **Creates** a GitHub release with the DMG attached
8. **Signs** the DMG for Sparkle using EdDSA
9. **Updates** the appcast XML with the new version info
10. **Deploys** the appcast to GitHub Pages

## Manual Release (Advanced)

If you need to create a release manually:

```bash
# Build
xcodebuild -project Toolbox.xcodeproj \
  -scheme Toolbox \
  -configuration Release \
  -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="Developer ID Application"

# Create DMG
create-dmg \
  --volname "Toolbox" \
  --window-pos 200 120 \
  --window-size 600 300 \
  --icon-size 100 \
  --app-drop-link 425 120 \
  "Toolbox.dmg" \
  "./build/Build/Products/Release/Toolbox.app"

# Sign DMG
codesign --sign "Developer ID Application" \
  --deep --force --options runtime --timestamp Toolbox.dmg

# Notarize
xcrun notarytool submit Toolbox.dmg \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAMID" \
  --wait

# Staple
xcrun stapler staple Toolbox.dmg

# Sign for Sparkle
./bin/sign_update Toolbox.dmg -f sparkle_key

# Update appcast manually
# (Edit docs/appcast.xml)

# Deploy to GitHub Pages
# (Push to gh-pages branch)
```

## Troubleshooting

### Workflow fails at "Sign DMG for Sparkle"

- Ensure `SPARKLE_EDDSA_KEY` secret is set correctly
- Verify the private key format (should be a long base64-encoded string)

### Appcast not updating

- Check that GitHub Pages is enabled
- Verify the `gh-pages` branch was updated
- Check workflow logs for deployment errors

### App doesn't detect updates

- Verify `SUFeedURL` is set correctly in Info.plist (should be `https://YOUR_USERNAME.github.io/toolbox/appcast.xml`)
- Check that the appcast XML is accessible in a browser
- Ensure the app has network entitlements (`com.apple.security.network.client`)
- Verify the public key in Info.plist matches the private key used for signing

### Notarization fails

- Check that hardened runtime is enabled
- Verify all code signing is correct
- Check Apple notarization logs in the workflow output

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, backwards compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes, backwards compatible

## Release Checklist

- [ ] Update version number in Xcode
- [ ] Update CHANGELOG.md
- [ ] Commit changes
- [ ] Create and push tag
- [ ] Monitor workflow completion
- [ ] Verify GitHub release created
- [ ] Verify appcast updated
- [ ] Test update detection in app
- [ ] Announce release (optional)

## Security Notes

- The EdDSA private key (`SPARKLE_EDDSA_KEY`) must be kept secret
- Never commit the private key to the repository
- Only the workflow should have access to the private key
- The public key is safe to include in the app bundle
- All releases are signed and notarized by Apple
- All update packages are cryptographically signed with EdDSA

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
