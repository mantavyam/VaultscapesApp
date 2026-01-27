### Production-Ready Persistent Sign-In in Flutter Apps: Guidelines and Direction

Most production Flutter apps (e.g., those using Firebase Auth, Supabase, AWS Amplify, or custom backend tokens) achieve seamless "stay logged in" behavior by leveraging **secure, platform-native persistence** for authentication credentials. The goal is to restore the authenticated state automatically on cold starts (app fully killed and relaunched) without showing the onboarding/welcome screen to returning users.

#### How Production Apps Typically Handle This
1. **Persistent Auth Storage**:
   - Firebase Auth (most common) automatically persists the user's session using secure storage (SharedPreferences on Android, Keychain on iOS) with `Persistence.LOCAL` by default on mobile. Tokens are refreshed silently in the background.
   - Other services (Google Sign-In, Apple Sign-In, JWT-based backends) store refresh tokens securely and validate/refresh them on startup.
   - Explicit logout is the only way to clear this state.

2. **State Restoration Flow**:
   - On app launch, show a **neutral splash/loading screen** (often the branded native splash) while initializing Firebase/services and checking auth state.
   - Once auth state is confirmed (usually via a stream or async check), route the user:
     - Authenticated + onboarding complete → directly to main app (home/dashboard).
     - New/unauthenticated → onboarding/welcome flow.
   - This prevents any flash of the wrong screen (e.g., welcome screen briefly appearing for logged-in users).

3. **Avoiding Race Conditions and Flashes**:
   - Never set the initial route directly to the welcome/onboarding screen if authenticated users exist.
   - Use an **auth gate** or **initialization wrapper** that waits for auth restoration before deciding the destination.
   - Popular patterns:
     - A dedicated Splash/Init screen as the true initial route.
     - Listening to an auth state stream (real-time) rather than a one-time synchronous check.
     - Router-level guards that only redirect after initialization is complete.

4. **Common Implementations in Production**:
   - Apps like Duolingo, Spotify clones, banking apps, or any Firebase-based app use the "splash → restore → deep route" pattern.
   - Packages like `firebase_auth` + `go_router` or `auto_route` often combine with a stream-based provider.
   - Many use `FutureBuilder` or `StreamBuilder` at the root level to handle the decision.

#### Recommended Direction for Your App (Flutter + GoRouter + Providers)

Given your current setup (AuthProvider auto-initializes, checks current user, router redirect waits for !isLoading, returning users should go to home):

1. **Strengthen Auth Restoration Reliability**:
   - Ensure your `AuthRepository.getCurrentUser()` uses a reliable method that accounts for Firebase's asynchronous restoration. Prefer listening to `FirebaseAuth.instance.authStateChanges()` or `idTokenChanges()` stream in your provider instead of just `currentUser` (which can be null briefly on cold start).
   - This stream emits the restored user automatically once Firebase finishes initializing.

2. **Prevent Flash of Welcome Screen**:
   - Change your **initialLocation** from `/welcome` to a neutral **Splash/Loading screen** (a simple centered logo/progress indicator).
   - In this splash screen's `initState` or via your providers' initialization, wait for both AuthProvider and OnboardingProvider to finish loading.
   - Once ready, manually navigate using `context.go()` or `context.replace()` to the correct destination based on the combined state (authenticated + onboarding complete → home, else → welcome/profile setup).

3. **Refine Router Redirect Logic**:
   - Keep the redirect guard, but make it more defensive: if either provider is still loading, return the splash route path to stay there.
   - After loading completes, the redirect will naturally trigger on the next navigation (or you can force a refresh).
   - Alternatively, move the decision logic entirely to the splash screen and remove heavy redirect dependence for the cold-start case.

4. **Overall Flow Direction**:
   - App launch → Native splash (via flutter_native_splash) → Your custom SplashWidget as GoRouter initial route.
   - In SplashWidget: Use `MultiProvider` or listen to both providers → When both !isLoading, compute destination → `context.go(destination)` with `replace` to avoid back stack.
   - Subsequent navigations: Rely on your existing redirect guard to protect routes (e.g., prevent unauthenticated access to home).

5. **Additional Production Hardening**:
   - Initialize Firebase as early as possible (in `main()` before `runApp`).
   - Handle edge cases: network offline (Firebase still restores last known state), token expiry (silent refresh), or errors (fallback to unauthenticated).
   - Test thoroughly on cold starts: Kill app completely, relaunch, verify no welcome flash and direct to home for logged-in users.
   - Consider adding a short artificial delay on splash only in debug mode for testing the flow.

This pattern eliminates any visibility of the onboarding screen for returning logged-in users, ensures persistence across kills/restarts, and matches what most production Firebase/Flutter apps do. It builds directly on your existing provider + GoRouter setup with minimal restructuring.