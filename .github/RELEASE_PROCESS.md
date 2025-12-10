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

## Troubleshooting

### App doesn't detect updates

- Verify `SUFeedURL` is set correctly in Info.plist (should be `https://YOUR_USERNAME.github.io/toolbox/appcast.xml`)
- Check that the appcast XML is accessible in a browser
- Ensure the app has network entitlements (`com.apple.security.network.client`)
- Verify the public key in Info.plist matches the private key used for signing

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
