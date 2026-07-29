# Fix Plan - Dart Analysis & Gradle Issues

## Critical Syntax Errors
- [ ] 1. `attendance_screen.dart` - Fix `Rimport` → `import` on line 1
- [ ] 2. `schedules_screen.dart` - Fix missing closing `);` in `_showForm()`
- [ ] 3. `app_router.dart` - Remove duplicate imports (lines 35-61)
- [ ] 4. `documents_screen.dart` - Fix syntax error (expected ')')
- [ ] 5. `positions_screen.dart` - Fix syntax error (expected ')')

## Gradle / Android Build
- [ ] 6. Update gradle-wrapper.properties - Downgrade Gradle to 8.x or update JAVA_HOME
- [ ] 7. Ensure `JAVA_HOME` points to JDK 17

## Deprecated API Fixes
- [ ] 8. Replace `withOpacity` with `withValues(alpha:)` across all files
- [ ] 9. Fix `value:` → `initialValue:` on DropdownButtonFormField in common_widgets.dart
- [ ] 10. Fix `activeColor:` → `activeThumbColor:` in reports_screen.dart and contract_form.dart

## Code Cleanup
- [ ] 11. Remove unused imports
- [ ] 12. Fix dead null-aware expressions in firestore_service.dart
- [ ] 13. Fix `__` → `_` unnecessary underscores
- [ ] 14. Fix curly braces in flow control structures

