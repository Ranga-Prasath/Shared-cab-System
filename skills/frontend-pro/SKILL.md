---
name: frontend-pro
description: Build, review, refactor, and style frontend user interfaces in React, Next.js, Vue, or plain web stacks. Use for component architecture, responsive layouts, CSS/Tailwind styling, animation behavior, accessibility remediation, and frontend performance tuning. Do not use for backend business logic, database schema changes, infrastructure, or CI/CD pipeline work.
---

# Frontend Pro

Deliver production-ready, accessible, responsive frontend code that matches the repository's existing UI patterns.

## 1) Discover Before Editing
- Inspect the repo for existing UI system, component primitives, and styling conventions.
- Detect and follow the active styling approach (Tailwind, CSS Modules, Styled Components, etc.).
- Reuse existing tokens, spacing scales, typography, and component APIs before introducing new ones.
- Avoid introducing new UI libraries unless explicitly requested.

## 2) Implement with Clear Boundaries
- Build small, single-responsibility components.
- Separate presentation from stateful/business behavior with hooks/composables/helpers.
- Keep prop and state models explicit with strict TypeScript types.
- Avoid `any`; prefer discriminated unions and narrow types when behavior branches.

## 3) Responsive and Maintainable Styling
- Use mobile-first layouts and scale progressively to larger breakpoints.
- Prefer fluid sizing (`rem`, `%`, `clamp`, responsive utilities) over rigid pixel locking.
- Keep styles local and predictable; avoid global overrides unless required.
- Preserve visible focus states and interaction affordances across breakpoints and input modes.

## 4) Accessibility Requirements
- Use semantic landmarks and native interactive elements first.
- Provide accessible names for all controls (`aria-label`, `aria-labelledby`, or visible text).
- Ensure keyboard-only navigation works end-to-end (Tab, Shift+Tab, Enter, Space, Esc as applicable).
- Meet WCAG AA contrast targets for text and essential UI states.
- Announce dynamic UI changes when needed (`aria-live`, status messaging, dialog semantics).

## 5) Performance Expectations
- Prevent avoidable re-renders (stable props, memoization where it provides measurable benefit).
- Lazy-load heavy or below-the-fold modules/assets.
- Keep bundle impact low; avoid large dependencies for trivial UI behavior.
- Optimize media delivery (responsive sizes, modern formats when supported).

## 6) Verification Protocol (Always Run)
- Run lint and type checks after edits.
- Run relevant unit/integration tests if present.
- Resolve introduced warnings/errors before finishing.
- If a check cannot run, report exactly what was skipped and why.

## 7) Completion Standard
- Code compiles cleanly.
- UI works across mobile and desktop layouts.
- Keyboard and screen-reader basics are covered.
- Changes align with existing project conventions and design language.