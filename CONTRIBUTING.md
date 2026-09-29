# Contributing

Keep changes focused on Mac Screen Recorder's existing scope. Open an issue describing the behavior and a reproducible example before proposing a large feature.

- Use a small, readable commit with a Conventional Commit prefix such as `fix:`, `feat:`, or `test:`.
- Run `swift test` and build the shared Xcode scheme before submitting.
- Cover changed behavior with a regression test when practical.
- Check light/dark appearance, large type, keyboard navigation where applicable, and accessibility labels.
- Do not commit signing identities, credentials, real customer data, derived build products, or user-specific Xcode state.

The minimum OS is intentional. Use availability checks for optional newer APIs rather than raising the target without a clear need.
