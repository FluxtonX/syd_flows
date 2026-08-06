# SYD FLOW – AI Development Rules

> This document defines the permanent development rules for the SYD FLOW project.
> Every AI assistant (Antigravity) MUST follow these rules before making any changes.

---

## Project Identity

- **Project Name**: SYD FLOW
- **Platform**: Flutter
- **Architecture**: MVVM + Clean Architecture
- **State Management**: GetX (or existing project state management only)
- **Backend**: Firebase
- **Purpose**: Modern productivity & workflow application with premium UI, smooth animations, scalable architecture, and production-quality code.

---

## IMPORTANT RULE

Before changing ANY file:
1. Read the existing project structure.
2. Understand current implementation.
3. Preserve existing architecture.
4. Never rewrite working code unnecessarily.
5. Modify only the required feature.
6. Never break other modules.

---

## Folder Structure

Always keep this structure:
```
lib/
  core/
    constants/
    theme/
    colors/
    typography/
    animations/
    widgets/
    routes/
    utils/
    services/
  features/
    feature_name/
      data/
      domain/
      presentation/
  assets/
    images/
    icons/
    fonts/
    animations/
```
- Do not create random folders.
- Do not duplicate files.
- Keep everything modular.

---

## UI Rules

- The complete application must look like one professional product.
- Every screen must follow exactly the same design language.
- Never design one screen differently.

---

## Typography Rules

- Use ONLY the global font.
- Never hardcode fonts.
- Always import typography from `core/theme/`.
- All text sizes must stay consistent.
- Example text scales: Display, Headline, Title, Body, Label, Caption.
- Never randomly use font sizes.

---

## Colors

- Never hardcode colors.
- Always use `AppColors` inside `lib/core/constants/app_colors.dart` (or `core/theme/colors.dart` if referenced/migrated, but currently configured in `lib/core/constants/app_colors.dart`).
- Primary colors must stay consistent.
- Accent colors must stay consistent.
- Background colors must stay consistent.

---

## Glow Effect

- The application's premium identity is the glowing UI.
- Maintain glowing effects everywhere: Buttons, Cards, Borders, Active Icons, FAB, Important Sections.
- The glow should feel premium.
- Never overuse.
- Never remove glow from existing components.

---

## Animations

- Animations are a major part of SYD FLOW.
- Maintain smooth animations using: Fade, Scale, Slide, Hero, AnimatedContainer, Implicit animations.
- Avoid abrupt transitions.
- Every interaction should feel fluid.
- Animation duration should remain consistent.

---

## Border Radius

- Use one global radius system: Small, Medium, Large, Extra Large.
- Never use random values.

---

## Spacing

- Maintain consistent spacing: Padding, Margin, Section spacing, Card spacing, Button spacing, Input spacing.
- Never use random spacing values.

---

## Icons

- Use one icon style throughout the project.
- Never mix different icon styles.
- Keep icon sizes consistent.

---

## Buttons

Buttons must have:
- Rounded corners
- Glow
- Smooth animation
- Consistent height
- Consistent typography
- Consistent padding
- Never create different button styles without reason.

---

## Inputs

All TextFields must have:
- Same height
- Same radius
- Same border style
- Same focus animation
- Same typography

---

## Cards

Cards must follow:
- Same radius
- Same shadow
- Same glow
- Same spacing
- Same padding
- Never create inconsistent cards.

---

## Responsive Design

Every screen must support:
- Android
- iPhone
- Small devices
- Large devices
- Tablet (future ready)
- No overflow.
- No clipped UI.
- No fixed sizes unless absolutely necessary.

---

## Code Quality

- Always write production-ready code.
- No duplicate logic.
- No dead code.
- No commented old code.
- No unnecessary files.
- No unnecessary packages.
- No hacks.
- No temporary fixes.
- Always clean architecture.

---

## Naming

- Use meaningful names (e.g., `TaskCard`, `FlowDashboard`, `AppButton`, `TaskRepository`, `TaskViewModel`).
- Avoid: `test.dart`, `new.dart`, `abc.dart`, `temp.dart`.

---

## Performance

- Minimize rebuilds.
- Optimize animations.
- Use `const` widgets whenever possible.
- Dispose controllers properly.
- Avoid memory leaks.
- Keep scrolling smooth.

---

## Existing Code

- Respect existing implementation.
- Do NOT replace working systems.
- Do NOT redesign the app unless requested.
- Improve instead of rewriting.

---

## Firebase

- Never modify Firestore structure unless requested.
- Never rename collections.
- Never remove fields.
- Maintain backward compatibility.

---

## Assets

- Never duplicate images.
- Reuse existing assets.
- Fonts must remain centralized.
- Animations must remain organized.

---

## Design Philosophy

SYD FLOW is a premium application.
The UI should feel:
- Minimal
- Modern
- Elegant
- Smooth
- Premium
- Fast
- Consistent
- Professional
- Every new screen must match the existing design.
- Never introduce inconsistent UI.

---

## AI Behaviour

Before writing code:
1. Analyze.
2. Plan.
3. Then implement.

- Prefer improving existing code.
- Avoid unnecessary refactoring.
- Keep the project maintainable.
- Always preserve architecture, UI consistency, animation consistency, typography, color system, spacing, glow effects, responsiveness, and clean architecture.

---

## Final Rule

If a requested change conflicts with existing architecture or design system:
**DO NOT implement blindly.**
Instead:
1. Analyze the impact.
2. Preserve the existing design language.
3. Suggest the safest implementation.
4. Then implement.

SYD FLOW must always remain a premium, scalable, production-ready Flutter application.
