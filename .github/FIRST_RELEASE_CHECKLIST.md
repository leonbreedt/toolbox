# First Release Checklist

Follow these steps in order to complete your first release with Sparkle updates.

## ✅ Pre-Release Setup (Do Once)

### Step 1: Generate Sparkle Keys

```bash
# Download Sparkle tools
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz -o sparkle.tar.xz
tar -xf sparkle.tar.xz
chmod +x bin/generate_keys

# Generate key pair
./bin/generate_keys

# Output will look like:
# PRIVATE KEY: base64string...
# PUBLIC KEY: another_base64string...

# Save both keys somewhere safe!
```

### Step 2: Add Public Key to Xcode

1. Open `Toolbox.xcodeproj` in Xcode
2. Select **Toolbox** target
3. Click **Build Settings** tab
4. Search for "SUPublicEDKey"
5. If not found, click **+** → **Add User-Defined Setting**
6. Name: `INFOPLIST_KEY_SUPublicEDKey`
7. Value: Paste your PUBLIC KEY (the base64 string without "PUBLIC KEY:" prefix)
8. Set for both Debug and Release configurations
9. Save the project (⌘S)

### Step 3: Add Private Key to GitHub

1. Go to https://github.com/YOUR_USERNAME/toolbox
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SPARKLE_EDDSA_KEY`
5. Value: Paste your **entire PRIVATE KEY line** (including "PRIVATE KEY:" prefix)
6. Click **Add secret**

### Step 4: Enable GitHub Pages

1. Go to https://github.com/YOUR_USERNAME/toolbox
2. Click **Settings** → **Pages**
3. Under **Build and deployment**:
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** (will be created automatically)
   - Folder: **/ (root)**
4. Click **Save**

### Step 5: Verify GitHub Secrets

Ensure all these secrets exist:

- [ ] `MACOS_CERTIFICATE`
- [ ] `MACOS_CERTIFICATE_PASSWORD`
- [ ] `KEYCHAIN_PASSWORD`
- [ ] `APPLE_ID`
- [ ] `APPLE_APP_SPECIFIC_PASSWORD`
- [ ] `APPLE_TEAM_ID`
- [ ] `SPARKLE_EDDSA_KEY` (just added)

## ✅ Creating the First Release

### Step 6: Verify Local Build

Before creating a release, test locally:

```bash
# Clean build
xcodebuild clean -project Toolbox.xcodeproj -scheme Toolbox

# Build
xcodebuild -project Toolbox.xcodeproj \
  -scheme Toolbox \
  -configuration Release \
  -derivedDataPath ./build

# Run the app
open build/Build/Products/Release/Toolbox.app
```

Verify:
- [ ] App launches without crashes
- [ ] Status bar icon appears
- [ ] Menu shows "Check for Updates…"
- [ ] Tools work correctly

### Step 7: Commit Sparkle Integration

```bash
# Stage all changes
git add .

# Commit
git commit -m "feat: add Sparkle auto-update support

- Integrate Sparkle 2.8.1 framework
- Add network entitlements for update checks
- Configure appcast feed on GitHub Pages
- Add Check for Updates menu item
- Update build workflow for automatic releases"

# Push to main
git push origin main
```

### Step 8: Create Release Tag

```bash
# Create annotated tag for version 1.0.4
git tag -a v1.0.4 -m "Release version 1.0.4

- Tool windows can now be dismissed using Escape or Command-W
- Added automatic update checking via Sparkle"

# Push the tag (this triggers the release workflow)
git push origin v1.0.4
```

### Step 9: Monitor the Workflow

1. Go to https://github.com/YOUR_USERNAME/toolbox/actions
2. Click on the running "Build macOS DMG" workflow
3. Watch the steps execute:
   - ✓ Build app
   - ✓ Sign app
   - ✓ Create DMG
   - ✓ Notarize DMG
   - ✓ Create GitHub Release
   - ✓ Sign for Sparkle
   - ✓ Update appcast
   - ✓ Deploy to GitHub Pages

This takes about 10-15 minutes.

### Step 10: Verify the Release

After workflow completes:

#### A. Check GitHub Release
1. Go to https://github.com/YOUR_USERNAME/toolbox/releases
2. Verify "v1.0.4" release exists
3. Verify `Toolbox.dmg` is attached
4. Download and test the DMG

#### B. Check Appcast
1. Go to https://YOUR_USERNAME.github.io/toolbox/appcast.xml
2. You should see XML with your release info
3. Verify it contains:
   - `<title>Version 1.0.4</title>`
   - Download URL
   - EdDSA signature

#### C. Test the DMG
```bash
# Download the DMG
curl -L -o Toolbox.dmg \
  https://github.com/YOUR_USERNAME/toolbox/releases/download/v1.0.4/Toolbox.dmg

# Verify code signature
codesign -vvv --deep --strict Toolbox.dmg

# Verify notarization
spctl -a -vvv -t install Toolbox.dmg

# Mount and run
open Toolbox.dmg
# Drag app to Applications and run
```

#### D. Test Updates (for next release)

After your second release, test the update flow:
1. Install version 1.0.4
2. Release version 1.0.5
3. Launch 1.0.4
4. Click "Check for Updates…"
5. Verify update prompt appears
6. Install the update
7. Verify app relaunches with 1.0.5

## 🎉 Success Criteria

Your first release is successful when:

- [x] GitHub Actions workflow completed without errors
- [x] GitHub Release page shows v1.0.4 with DMG
- [x] Appcast XML is accessible at GitHub Pages URL
- [x] DMG downloads and mounts correctly
- [x] App launches from DMG without issues
- [x] "Check for Updates…" menu item appears
- [x] No crashes or errors in Console.app

## 📋 Future Releases

For subsequent releases, the process is much simpler:

```bash
# 1. Update version in Xcode
# 2. Update CHANGELOG.md
# 3. Commit changes
git add .
git commit -m "build: bump version to 1.0.5"
git push

# 4. Create and push tag
git tag -a v1.0.5 -m "Release version 1.0.5"
git push origin v1.0.5

# 5. Wait for workflow to complete
# 6. Done! Users will be notified automatically
```

See [RELEASE_QUICK_REFERENCE.md](RELEASE_QUICK_REFERENCE.md) for the streamlined process.

## ❌ Common Issues

### Issue: "Public key not found"
**Solution:** Verify `INFOPLIST_KEY_SUPublicEDKey` is set correctly in Xcode build settings

### Issue: Workflow fails at "Sign DMG for Sparkle"
**Solution:** Check that `SPARKLE_EDDSA_KEY` secret is set and matches the private key

### Issue: Appcast not found (404)
**Solution:**
1. Check GitHub Pages is enabled
2. Verify workflow "Deploy to GitHub Pages" step succeeded
3. Wait 2-3 minutes for GitHub Pages to deploy

### Issue: App can't connect to update feed
**Solution:**
1. Verify `INFOPLIST_KEY_SUFeedURL` in build settings
2. Check entitlements include `com.apple.security.network.client`
3. Look for errors in Console.app

### Issue: Update signature invalid
**Solution:** Ensure the public and private keys match (regenerate if needed)

## 🔧 Troubleshooting Commands

```bash
# Check what's in the Info.plist
/usr/libexec/PlistBuddy -c "Print" \
  build/Build/Products/Release/Toolbox.app/Contents/Info.plist | grep -i sparkle

# Check code signing
codesign -dvvv build/Build/Products/Release/Toolbox.app

# Check entitlements
codesign -d --entitlements - build/Build/Products/Release/Toolbox.app

# Watch Console logs
log stream --predicate 'subsystem == "org.sparkle-project.Sparkle"' --level debug
```

## 📚 Reference Documents

- [RELEASE_PROCESS.md](RELEASE_PROCESS.md) - Complete release documentation
- [RELEASE_QUICK_REFERENCE.md](RELEASE_QUICK_REFERENCE.md) - Quick command reference
- [SPARKLE_SETUP_SUMMARY.md](SPARKLE_SETUP_SUMMARY.md) - What was integrated
- [SIGNING_SETUP.md](SIGNING_SETUP.md) - Code signing setup

## ✉️ Need Help?

If you encounter issues:
1. Check the workflow logs on GitHub Actions
2. Review Console.app for errors
3. Verify all secrets are set correctly
4. Check the Sparkle documentation: https://sparkle-project.org/documentation/

Good luck with your first release! 🚀
