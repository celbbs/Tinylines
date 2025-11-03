# TinyLines

*"A lightweight journaling app designed to help users capture one meaningful thought or memory each day through short entries and optional photos."*

**Team:** Celia Babbs, Kuenaokeao Borling, Charles Loughin, Arianna Joffrion
**Course:** CS461-400 Fall 2025
**Institution:** Oregon State University

---

## Summary

The core additions beyond the base Flutter project setup are as follows:

### Core Architecture:
- lib/models/journal_entry.dart - Data model with date-based IDs, content, and optional image paths
- lib/services/storage_service.dart - Local file storage using markdown + JSON
- lib/providers/journal_provider.dart - State management with Provider pattern

### User Interface:
- lib/screens/home_screen.dart - Calendar view with recent entries list
- lib/screens/entry_editor_screen.dart - Entry creation/editing with photo support
- lib/utils/app_theme.dart - Minimalist design system with calm colors

## TODO
- [ ] file writing bug (may be on emulator side rather than a direct code issue)
- [ ] further manual testing
- [ ] add unit tests


## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [FlutterFire Documentation](https://firebase.google.com/docs/flutter/setup)
- [Provider State Management](https://pub.dev/packages/provider)
