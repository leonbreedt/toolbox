# Quick Release Reference

A condensed guide for creating releases. For full details, see [RELEASE_PROCESS.md](RELEASE_PROCESS.md).

## Quick Release Steps

```bash
# 1. Update version in Xcode (e.g., 1.0.3 → 1.0.4)

# 2. Update CHANGELOG.md with changes

# 3. Commit and push
git add .
git commit -m "build: bump version to 1.0.4"
git push origin main

# 4. Create and push tag
git tag -a v1.0.4 -m "Release version 1.0.4"
git push origin v1.0.4

# 5. Wait for GitHub Actions to complete
# 6. Verify release at https://github.com/YOUR_USERNAME/toolbox/releases
```

## What Gets Automated

✅ Build and sign the app
✅ Create and notarize DMG
✅ Create GitHub release
✅ Sign update with Sparkle
✅ Update appcast feed
✅ Deploy to GitHub Pages

## First Release Only

Set up the Sparkle EdDSA key:

```bash
# Generate key pair
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz -o sparkle.tar.xz
tar -xf sparkle.tar.xz
./bin/generate_keys

# Add private key to GitHub Secrets as SPARKLE_EDDSA_KEY
# Add public key to Xcode build settings as INFOPLIST_KEY_SUPublicEDKey
```

Enable GitHub Pages:
- Settings → Pages → Source: gh-pages branch, / (root)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No updates detected | Check SUFeedURL in Info.plist and verify appcast is accessible |
| Workflow fails | Check GitHub Actions logs; ensure all secrets are set |
| Notarization fails | Verify Apple ID, app-specific password, and team ID |

## Required Secrets

- `MACOS_CERTIFICATE` - Base64 encoded P12 certificate
- `MACOS_CERTIFICATE_PASSWORD` - P12 password
- `KEYCHAIN_PASSWORD` - Temporary keychain password
- `APPLE_ID` - Apple ID email
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `APPLE_TEAM_ID` - Team ID
- `SPARKLE_EDDSA_KEY` - Sparkle EdDSA private key

## URLs

- Appcast: `https://YOUR_USERNAME.github.io/toolbox/appcast.xml`
- Releases: `https://github.com/YOUR_USERNAME/toolbox/releases`
