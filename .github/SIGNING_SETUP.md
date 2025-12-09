# Code Signing and Notarization Setup

This document explains how to set up the required secrets for code signing and notarization in GitHub Actions.

## Prerequisites

1. **Apple Developer Account** - You need a paid Apple Developer account ($99/year)
2. **Developer ID Application Certificate** - For distributing apps outside the Mac App Store
3. **App-Specific Password** - For notarization

## Step 1: Create Developer ID Certificate

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the "+" button to create a new certificate
3. Select "Developer ID Application" under "Software"
4. Follow the instructions to create a Certificate Signing Request (CSR) using Keychain Access
5. Upload the CSR and download your certificate
6. Install the certificate in your Keychain

## Step 2: Export Certificate as P12

1. Open **Keychain Access** on your Mac
2. Find your "Developer ID Application" certificate in the "My Certificates" section
3. Right-click and select "Export"
4. Choose format: **Personal Information Exchange (.p12)**
5. Save with a strong password (you'll need this later)
6. Convert to base64:
   ```bash
   base64 -i /path/to/certificate.p12 | pbcopy
   ```
   This copies the base64-encoded certificate to your clipboard

## Step 3: Create App-Specific Password

1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID
3. In the "Security" section, under "App-Specific Passwords", click "Generate Password"
4. Enter a label (e.g., "GitHub Actions Notarization")
5. Copy the generated password

## Step 4: Get Your Team ID

1. Go to [Apple Developer Membership](https://developer.apple.com/account/#/membership/)
2. Your Team ID is listed under "Team ID"
3. Copy this ID (it's a 10-character alphanumeric string like "ABCDE12345")

## Step 5: Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add the following secrets:

### Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `MACOS_CERTIFICATE` | Base64-encoded P12 certificate | (long base64 string) |
| `MACOS_CERTIFICATE_PASSWORD` | Password for the P12 certificate | `YourStrongPassword123` |
| `KEYCHAIN_PASSWORD` | Temporary keychain password (can be any strong password) | `TempPassword456` |
| `APPLE_ID` | Your Apple ID email | `your.email@example.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from Step 3 | `abcd-efgh-ijkl-mnop` |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID | `ABCDE12345` |

## Step 6: Test the Workflow

1. Commit and push changes to the `main` branch
2. Go to the **Actions** tab in your GitHub repository
3. Watch the workflow run
4. The signed and notarized DMG will be available as an artifact

## Creating Releases

To create a GitHub release with the DMG:

1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The workflow will automatically:
   - Build and sign the app
   - Notarize with Apple
   - Create a DMG
   - Sign and notarize the DMG
   - Create a GitHub release with the DMG attached

## Troubleshooting

### Notarization fails
- Verify your Apple ID and app-specific password are correct
- Check that your certificate is valid and not expired
- Ensure hardened runtime is enabled in build settings

### Code signing fails
- Verify the certificate is properly base64-encoded
- Check that the certificate password is correct
- Ensure the certificate is a "Developer ID Application" certificate

### Build fails on PR
- PRs use unsigned builds, so secrets aren't required
- If PRs fail, check the Xcode project settings

## Security Notes

- Never commit secrets to your repository
- Secrets are only available to workflows running on the `main` branch and tags
- Pull request workflows run without code signing to avoid exposing secrets
- The temporary keychain is destroyed after the workflow completes

## Additional Resources

- [Apple Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode/build-settings-reference)
