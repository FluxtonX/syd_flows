# Subscription access setup

The admin chooses **Free Access** or **Paid / Premium** when uploading a video.
The upload writes one canonical access flag to `videos`: `isPaid` (and the
compatibility fields `premium` and `isFree`). The Flutter app can list both
tiers, but it blocks the player for a paid video unless the signed-in user has
an active entitlement.

## Entitlement document

After a successful, verified payment, your payment backend must write this to
the user's Firestore document with the Firebase Admin SDK:

```json
{
  "subscription": {
    "status": "active",
    "planId": "monthly",
    "source": "app_store",
    "expiresAt": "<Firestore Timestamp>"
  }
}
```

`status` may also be `trialing`; both values work only until `expiresAt`. For
cancelled, expired, refunded, or failed payments, write a non-active status or
an expiry in the past. Never write this field from Flutter—the Firestore rules
explicitly prevent it.

## Production payment provider

Connect the subscription CTA to either Apple/Google in-app purchases (usually
RevenueCat is the simplest unified option) or a server-side payment provider.
The provider webhook must validate the purchase and update the entitlement
document above. Do not trust a client-side "payment successful" result.

## Protecting the actual video files

The app gate prevents playback in this client. For real content protection,
premium Cloudinary videos must also use authenticated/signed delivery and a
backend endpoint that issues a short-lived URL only for active subscribers.
Public Cloudinary URLs can otherwise be shared outside the app.
