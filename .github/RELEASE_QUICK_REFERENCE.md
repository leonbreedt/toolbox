# Quick Release Reference

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

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No updates detected | Check SUFeedURL in Info.plist and verify appcast is accessible |
| Workflow fails | Check GitHub Actions logs; ensure all secrets are set |
| Notarization fails | Verify Apple ID, app-specific password, and team ID |
