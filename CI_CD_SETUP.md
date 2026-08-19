# iOS CI/CD — Setup Guide

## How It Works

Jab bhi aap ek version tag push karo, GitHub Actions automatically:
1. Flutter iOS build karega (signed, release mode)
2. Version number tag se extract karega (v1.0.5 → build name 1.0.5, build number 5)
3. `.ipa` file TestFlight par upload karega

## Trigger Command

```bash
git tag v1.0.1
git push origin v1.0.1
```

---

## One-Time Setup (Zaroor karna hai)

### Step 1: ExportOptions.plist update karo

`ios/ExportOptions.plist` mein apna Team ID set karo:
- https://developer.apple.com → Account → Membership → Team ID copy karo
- `YOUR_TEAM_ID` replace karo
- `syd_flow Distribution` ko apne actual provisioning profile ke naam se replace karo

### Step 2: GitHub Secrets Add karo

GitHub repo → Settings → Secrets and variables → Actions → New repository secret

| Secret Name | Kaise banao |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | `base64 -i distribution.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | P12 file ka password |
| `KEYCHAIN_PASSWORD` | Koi bhi strong random string (e.g. `MyKeychainPass123`) |
| `APPLE_PROVISIONING_PROFILE_BASE64` | `base64 -i syd_flow.mobileprovision \| pbcopy` |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect → Users → Keys → Issuer ID |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Keys → Key ID |
| `APP_STORE_CONNECT_KEY_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

### Step 3: Provisioning Profile name match karo

`ios/ExportOptions.plist` mein `provisioningProfiles` dict mein profile name wahi hona chahiye jo Xcode mein dikh raha hai:
- Xcode → Runner target → Signing & Capabilities → Provisioning Profile ka naam

---

## Files Created

```
.github/
  workflows/
    ios_build.yml    ← Main CI/CD workflow
ios/
  ExportOptions.plist ← IPA export config (update YOUR_TEAM_ID)
```

---

## Version Naming Convention

| Tag | Build Name | Build Number |
|---|---|---|
| v1.0.1 | 1.0.1 | 1 |
| v1.0.5 | 1.0.5 | 5 |
| v1.2.10 | 1.2.10 | 10 |

> **Note**: Build number (last segment) App Store Connect mein unique hona chahiye.
> Isliye patch version always increment karo (v1.0.1, v1.0.2…)

---

## Monitoring

Build status dekho: `https://github.com/FluxtonX/syd_flows/actions`
