# Contributing to Tack

Thank you for your interest in contributing to Tack. We welcome contributions from the community, whether you are fixing a bug, improving documentation, or proposing new enhancements.

---

## Code of Conduct

Please help maintain a welcoming, respectful, and constructive environment. Treat all contributors and users with courtesy and respect.

---

## How to Contribute

### 1. Reporting Bugs

Before creating a new bug report, search the existing issues to ensure the issue has not already been reported.

When opening an issue, provide as much relevant context as possible:
- A clear, descriptive title.
- Steps to reproduce the behavior.
- Expected behavior vs. actual behavior.
- Relevant device details (e.g., Android version, device model).
- Flutter environment details (`flutter doctor -v` output, if relevant).
- Screenshots or screen recordings when visual elements are affected.

### 2. Proposing Enhancements

If you have ideas for improvements:
1. Check existing issues and discussions to avoid duplicate topics.
2. Open a feature proposal issue explaining the problem you want to solve, the proposed solution, and any alternatives considered.
3. Note that features should align with the project's focus as an offline-first, tactile mobile workspace.

### 3. Submitting Code Changes

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/<your-username>/notes.git
   cd notes
   ```

2. **Create a Topic Branch**:
   ```bash
   git checkout -b fix/issue-description
   ```
   or
   ```bash
   git checkout -b feat/feature-name
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Adhere to Code Standards**:
   - Follow standard Dart and Flutter formatting conventions (`dart format .`).
   - Adhere to the lint rules defined in `analysis_options.yaml`.
   - Keep classes and functions modular, following the project's domain-driven layered architecture.
   - Respect the established design tokens (`DM Sans` typography, 8 curated pastels, `HeroIcons` / `LucideIcons`).

5. **Commit Your Changes**:
   Write clear, concise commit messages following standard conventions:
   ```
   feat: add support for markdown checklists
   fix: correct coordinate bounds on canvas pan
   docs: update setup instructions in README
   ```

6. **Submit a Pull Request**:
   - Push your branch to your fork.
   - Open a Pull Request targeting the `main` branch.
   - Describe the changes made and reference any related issue numbers (e.g., `Fixes #12`).
   - Fill out the PR template checklist.

---

## Review Process

- Pull requests are reviewed by maintainers when time permits.
- Submitting a pull request does not guarantee that it will be merged or reviewed within a specific timeframe.
- Constructive feedback may be requested before a pull request is merged.

---

## Licensing

By contributing to Tack, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
