# LessDo 1.0 Release Checklist

## Publisher setup

- Replace the support contact placeholder in the in-app privacy policy.
- Host `docs/PRIVACY_POLICY.md` on a public HTTPS URL for store metadata.
- Configure Apple Developer and Google Play signing credentials.
- Copy `android/key.properties.example` to `android/key.properties` and fill
  it with the publisher-owned upload keystore before the Play Store build.
- Create the monthly and yearly subscription products.
- Add localized store copy, screenshots, category, age rating, and review notes.

## App Store Connect

- Bundle ID: `com.nightelf.lessdo`
- Version: `1.0.0`
- Build: `1`
- Subscription IDs: `lessdo_premium_monthly`, `lessdo_premium_yearly`
- Include Apple's Standard EULA URL in the listing.
- Complete App Privacy answers based on the final support, analytics, and backend setup.

## Final device checks

- Create, edit, complete, and delete tasks.
- Verify reminders after permission approval.
- Verify Face ID or Touch ID on a physical device.
- Verify purchase and restore flows with sandbox accounts.
- Open both documented `lessdo://` URL forms.
- Test sharing, all focus timer modes, rotation, large text, and iPad layout.
- Archive with release signing and upload to TestFlight before review.
