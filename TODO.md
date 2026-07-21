# TODO
- [ ] Inspect & reproduce the “Upload contrat signé échoué” path in `employee_form_screen.dart`.
- [ ] Add better error reporting around the contrat signé upload (include path + stacktrace) so the creation failure is explainable.
- [ ] Ensure the contrat signé file can be uploaded on both web and mobile (check file types passed to `uploadDocument`).
- [ ] Add guard: if contrat signé is required, validate before upload (and show clear message instead of throwing).
- [ ] Run `flutter analyze` and `flutter test` (or at least compile) to confirm no new errors.

