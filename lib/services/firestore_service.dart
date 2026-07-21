import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/employee_model.dart';
import '../models/department_model.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Audit Log ───────────────────────────────────────────────────────────────
  Future<void> addAuditLog({
    required String userId,
    required String userNom,
    required String action,
    required String collection,
    required String documentId,
    required String description,
  }) async {
    await _db
        .collection(AppConstants.colAuditLogs)
        .add(
          AuditLogModel(
            id: '',
            userId: userId,
            userNom: userNom,
            action: action,
            collection: collection,
            documentId: documentId,
            description: description,
            createdAt: DateTime.now(),
          ).toFirestore(),
        );
  }

  Stream<List<AuditLogModel>> watchAuditLogs() {
    return _db
        .collection(AppConstants.colAuditLogs)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(AuditLogModel.fromFirestore).toList());
  }

  // ─── Employees ───────────────────────────────────────────────────────────────
  Stream<List<EmployeeModel>> watchEmployees({
    String? departementId,
    String? statut,
  }) {
    Query q = _db.collection(AppConstants.colEmployees);
    if (departementId != null)
      q = q.where('departementId', isEqualTo: departementId);
    if (statut != null) q = q.where('statut', isEqualTo: statut);
    return q
        .orderBy('nom')
        .snapshots()
        .map((s) => s.docs.map(EmployeeModel.fromFirestore).toList());
  }

  Future<EmployeeModel?> getEmployee(String id) async {
    final doc = await _db.collection(AppConstants.colEmployees).doc(id).get();
    return doc.exists ? EmployeeModel.fromFirestore(doc) : null;
  }

  Future<String> addEmployee(EmployeeModel emp) async {
    final ref = await _db
        .collection(AppConstants.colEmployees)
        .add(emp.toFirestore());
    await _updateDeptCount(emp.departementId);
    return ref.id;
  }

  Future<void> updateEmployee(EmployeeModel emp) async {
    await _db
        .collection(AppConstants.colEmployees)
        .doc(emp.id)
        .update(emp.toFirestore());
  }

  Future<void> deleteEmployee(String id, String departementId) async {
    await _db.collection(AppConstants.colEmployees).doc(id).delete();
    await _updateDeptCount(departementId);
  }

  Future<List<EmployeeModel>> searchEmployees(String query) async {
    final q = query.toLowerCase();
    final snap = await _db
        .collection(AppConstants.colEmployees)
        .where('searchIndex', arrayContains: q)
        .get();
    return snap.docs.map(EmployeeModel.fromFirestore).toList();
  }

  Future<String> generateMatricule() async {
    final snap = await _db
        .collection(AppConstants.colEmployees)
        .orderBy('matricule', descending: true)
        .limit(1)
        .get();
    final last = snap.docs.isNotEmpty ? snap.docs.first.get('matricule') as String? : null;
    if (last == null || last.isEmpty) return 'EMP0001';
    final num = int.tryParse(last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'EMP${(num + 1).toString().padLeft(4, '0')}';
  }

  // ─── Departments ─────────────────────────────────────────────────────────────
  Stream<List<DepartmentModel>> watchDepartments() {
    return _db
        .collection(AppConstants.colDepartments)
        .orderBy('nom')
        .snapshots()
        .map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());
  }

  Future<String> addDepartment(DepartmentModel dept) async {
    final ref = await _db
        .collection(AppConstants.colDepartments)
        .add(dept.toFirestore());
    return ref.id;
  }

  Future<void> updateDepartment(DepartmentModel dept) async {
    await _db
        .collection(AppConstants.colDepartments)
        .doc(dept.id)
        .update(dept.toFirestore());
  }

  Future<void> deleteDepartment(String id) async {
    await _db.collection(AppConstants.colDepartments).doc(id).delete();
  }

  Future<void> _updateDeptCount(String deptId) async {
    final snap = await _db
        .collection(AppConstants.colEmployees)
        .where('departementId', isEqualTo: deptId)
        .count()
        .get();
    await _db.collection(AppConstants.colDepartments).doc(deptId).update({
      'nombreEmployes': snap.count ?? 0,
    });
  }

  // ─── Positions ───────────────────────────────────────────────────────────────
  Stream<List<PositionModel>> watchPositions() {
    return _db
        .collection(AppConstants.colPositions)
        .orderBy('titre')
        .snapshots()
        .map((s) => s.docs.map(PositionModel.fromFirestore).toList());
  }

  Future<String> addPosition(PositionModel pos) async {
    final ref = await _db
        .collection(AppConstants.colPositions)
        .add(pos.toFirestore());
    return ref.id;
  }

  Future<void> updatePosition(PositionModel pos) async {
    await _db
        .collection(AppConstants.colPositions)
        .doc(pos.id)
        .update(pos.toFirestore());
  }

  Future<void> deletePosition(String id) async {
    await _db.collection(AppConstants.colPositions).doc(id).delete();
  }

  // ─── Contracts ───────────────────────────────────────────────────────────────
  Stream<List<ContractModel>> watchContracts({String? employeeId}) {
    Query q = _db.collection(AppConstants.colContracts);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q
        .orderBy('dateDebut', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ContractModel.fromFirestore).toList());
  }

  Future<String> addContract(ContractModel c) async {
    final ref = await _db
        .collection(AppConstants.colContracts)
        .add(c.toFirestore());
    return ref.id;
  }

  Future<void> updateContract(ContractModel c) async {
    await _db
        .collection(AppConstants.colContracts)
        .doc(c.id)
        .update(c.toFirestore());
  }

  Future<void> deleteContract(String id) async {
    await _db.collection(AppConstants.colContracts).doc(id).delete();
  }

  // ─── Attendance ──────────────────────────────────────────────────────────────
  Stream<List<AttendanceModel>> watchAttendance({
    DateTime? date,
    String? employeeId,
  }) {
    Query q = _db.collection(AppConstants.colAttendance);
    if (date != null) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      q = q.where('dateStr', isEqualTo: dateStr);
    }
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q.snapshots().map((s) {
      try {
        return s.docs.map(AttendanceModel.fromFirestore).toList()..sort((a, b) {
          final da = a.heureArrivee ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.heureArrivee ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });
      } catch (e) {
        return <AttendanceModel>[];
      }
    });
  }

  Future<String> addAttendance(AttendanceModel a) async {
    final ref = await _db
        .collection(AppConstants.colAttendance)
        .add(a.toFirestore());
    return ref.id;
  }

  Future<void> updateAttendance(AttendanceModel a) async {
    await _db
        .collection(AppConstants.colAttendance)
        .doc(a.id)
        .update(a.toFirestore());
  }

  Future<void> deleteAttendance(String id) async {
    await _db.collection(AppConstants.colAttendance).doc(id).delete();
  }

  // ─── Leaves ──────────────────────────────────────────────────────────────────
  Stream<List<LeaveModel>> watchLeaves({String? employeeId, String? statut}) {
    Query q = _db.collection(AppConstants.colLeaves);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    if (statut != null) q = q.where('statut', isEqualTo: statut);
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LeaveModel.fromFirestore).toList());
  }

  Future<String> addLeave(LeaveModel l) async {
    final ref = await _db
        .collection(AppConstants.colLeaves)
        .add(l.toFirestore());
    return ref.id;
  }

  Future<void> updateLeave(LeaveModel l) async {
    await _db
        .collection(AppConstants.colLeaves)
        .doc(l.id)
        .update(l.toFirestore());
  }

  Future<void> updateLeaveStatus(
    String id,
    String statut,
    String validePar,
    String? commentaire,
  ) async {
    await _db.collection(AppConstants.colLeaves).doc(id).update({
      'statut': statut,
      'validePar': validePar,
      'commentaireRH': commentaire,
      'dateValidation': Timestamp.now(),
    });
  }

  // ─── Payroll ─────────────────────────────────────────────────────────────────
  Stream<List<PayrollModel>> watchPayroll({
    int? mois,
    int? annee,
    String? employeeId,
  }) {
    Query q = _db.collection(AppConstants.colPayroll);
    if (mois != null) q = q.where('mois', isEqualTo: mois);
    if (annee != null) q = q.where('annee', isEqualTo: annee);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q.snapshots().map((s) {
      try {
        return s.docs.map(PayrollModel.fromFirestore).toList()..sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      } catch (e) {
        return <PayrollModel>[];
      }
    });
  }

  Future<String> addPayroll(PayrollModel p) async {
    final ref = await _db
        .collection(AppConstants.colPayroll)
        .add(p.toFirestore());
    return ref.id;
  }

  Future<void> updatePayroll(PayrollModel p) async {
    await _db
        .collection(AppConstants.colPayroll)
        .doc(p.id)
        .update(p.toFirestore());
  }

  Future<void> deletePayroll(String id) async {
    await _db.collection(AppConstants.colPayroll).doc(id).delete();
  }

  // ─── Sanctions ───────────────────────────────────────────────────────────────
  Stream<List<SanctionModel>> watchSanctions({String? employeeId}) {
    Query q = _db.collection(AppConstants.colSanctions);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SanctionModel.fromFirestore).toList());
  }

  Future<String> addSanction(SanctionModel s) async {
    final ref = await _db
        .collection(AppConstants.colSanctions)
        .add(s.toFirestore());
    return ref.id;
  }

  Future<void> updateSanction(SanctionModel s) async {
    await _db
        .collection(AppConstants.colSanctions)
        .doc(s.id)
        .update(s.toFirestore());
  }

  Future<void> deleteSanction(String id) async {
    await _db.collection(AppConstants.colSanctions).doc(id).delete();
  }

  // ─── Trainings ───────────────────────────────────────────────────────────────
  Stream<List<TrainingModel>> watchTrainings({String? employeeId}) {
    Query q = _db.collection(AppConstants.colTrainings);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TrainingModel.fromFirestore).toList());
  }

  Future<String> addTraining(TrainingModel t) async {
    final ref = await _db
        .collection(AppConstants.colTrainings)
        .add(t.toFirestore());
    return ref.id;
  }

  Future<void> updateTraining(TrainingModel t) async {
    await _db
        .collection(AppConstants.colTrainings)
        .doc(t.id)
        .update(t.toFirestore());
  }

  Future<void> deleteTraining(String id) async {
    await _db.collection(AppConstants.colTrainings).doc(id).delete();
  }

  // ─── Evaluations ─────────────────────────────────────────────────────────────
  Stream<List<EvaluationModel>> watchEvaluations({String? employeeId}) {
    Query q = _db.collection(AppConstants.colEvaluations);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q
        .orderBy('annee', descending: true)
        .snapshots()
        .map((s) => s.docs.map(EvaluationModel.fromFirestore).toList());
  }

  Future<String> addEvaluation(EvaluationModel e) async {
    final ref = await _db
        .collection(AppConstants.colEvaluations)
        .add(e.toFirestore());
    return ref.id;
  }

  Future<void> updateEvaluation(EvaluationModel e) async {
    await _db
        .collection(AppConstants.colEvaluations)
        .doc(e.id)
        .update(e.toFirestore());
  }

  Future<void> deleteEvaluation(String id) async {
    await _db.collection(AppConstants.colEvaluations).doc(id).delete();
  }

  // ─── Documents ───────────────────────────────────────────────────────────────
  Stream<List<DocumentModel>> watchDocuments({String? employeeId}) {
    Query q = _db.collection(AppConstants.colDocuments);
    if (employeeId != null) q = q.where('employeeId', isEqualTo: employeeId);
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DocumentModel.fromFirestore).toList());
  }

  Future<String> uploadDocument(dynamic file, String path) async {
    final bytes = switch (file) {
      Uint8List web when kIsWeb => web,
      File f when !kIsWeb => await f.readAsBytes(),
      _ => throw UnsupportedError(
          'Type de fichier non supporté. kIsWeb=$kIsWeb, type=${file.runtimeType}'),
    };

    if (bytes.isEmpty) throw Exception('Fichier vide');
    final mimeType = guessMimeType(path);
    const chunkSize = 400 * 1024;
    final chunks = <List<int>>[];
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = i + chunkSize > bytes.length ? bytes.length : i + chunkSize;
      chunks.add(bytes.sublist(i, end));
    }
    final fileId = path.replaceAll('/', '_').replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    final batch = _db.batch();
    for (var i = 0; i < chunks.length; i++) {
      final chunkBase64 = base64Encode(chunks[i]);
      batch.set(_db.collection('employee_file_chunks').doc('$fileId-$i'), {
        'fileId': fileId,
        'chunkIndex': i,
        'totalChunks': chunks.length,
        'data': chunkBase64,
        'mimeType': mimeType,
        'path': path,
        'taille': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return fileId;
  }

  Future<String> getDocumentDataUrl(String fileId) async {
    final snap = await _db
        .collection('employee_file_chunks')
        .where('fileId', isEqualTo: fileId)
        .orderBy('chunkIndex')
        .get();
    if (snap.docs.isEmpty) throw Exception('Fichier introuvable');
    final totalChunks = snap.docs.first.get('totalChunks') as int? ?? snap.docs.length;
    if (snap.docs.length != totalChunks) throw Exception('Fichier incomplet');
    final mimeType = snap.docs.first.get('mimeType') as String? ?? 'application/octet-stream';
    final builder = StringBuffer(mimeType.length + 13 + (snap.docs.length * 400 * 1024 * 4 ~/ 3));
    builder.write('data:$mimeType;base64,');
    for (final doc in snap.docs) {
      final chunk = doc.get('data') as String;
      builder.write(chunk);
    }
    return builder.toString();
  }

  Future<Uint8List> getDocumentBytes(String fileId) async {
    final snap = await _db
        .collection('employee_file_chunks')
        .where('fileId', isEqualTo: fileId)
        .orderBy('chunkIndex')
        .get();
    if (snap.docs.isEmpty) throw Exception('Fichier introuvable');
    final totalChunks = snap.docs.first.get('totalChunks') as int? ?? snap.docs.length;
    if (snap.docs.length != totalChunks) throw Exception('Fichier incomplet');
    final chunks = <int>[];
    for (final doc in snap.docs) {
      final chunk = doc.get('data') as String;
      chunks.addAll(base64Decode(chunk));
    }
    return Uint8List.fromList(chunks);
  }

  String guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  Future<String> addDocument(DocumentModel doc) async {
    final ref = await _db
        .collection(AppConstants.colDocuments)
        .add(doc.toFirestore());
    return ref.id;
  }

  Future<void> deleteDocument(String id, String url) async {
    await _db.collection(AppConstants.colDocuments).doc(id).delete();
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  // ─── Recruitment ─────────────────────────────────────────────────────────────
  Stream<List<RecruitmentModel>> watchRecruitment() {
    return _db
        .collection(AppConstants.colRecruitment)
        .orderBy('datePublication', descending: true)
        .snapshots()
        .map((s) => s.docs.map(RecruitmentModel.fromFirestore).toList());
  }

  Future<String> addRecruitment(RecruitmentModel r) async {
    final ref = await _db
        .collection(AppConstants.colRecruitment)
        .add(r.toFirestore());
    return ref.id;
  }

  Future<void> updateRecruitment(RecruitmentModel r) async {
    await _db
        .collection(AppConstants.colRecruitment)
        .doc(r.id)
        .update(r.toFirestore());
  }

  Future<void> deleteRecruitment(String id) async {
    await _db.collection(AppConstants.colRecruitment).doc(id).delete();
  }

  // ─── Notifications ───────────────────────────────────────────────────────────
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _db
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> addNotification(NotificationModel n) async {
    await _db.collection(AppConstants.colNotifications).add(n.toFirestore());
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection(AppConstants.colNotifications).doc(id).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── Messages ────────────────────────────────────────────────────────────────
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _db
        .collection(AppConstants.colMessages)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<void> sendMessage(MessageModel m) async {
    await _db.collection(AppConstants.colMessages).add(m.toFirestore());
    await _db
        .collection(AppConstants.colConversations)
        .doc(m.conversationId)
        .update({
          'lastMessage': m.contenu,
          'lastMessageAt': Timestamp.fromDate(m.createdAt),
        });
  }

  Stream<List<Map<String, dynamic>>> watchConversations(String userId) {
    return _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String> createConversation(
    List<String> participants,
    String nom,
  ) async {
    final ref = await _db.collection(AppConstants.colConversations).add({
      'participants': participants,
      'nom': nom,
      'lastMessage': '',
      'lastMessageAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
    });
    return ref.id;
  }

  // ─── Agenda ──────────────────────────────────────────────────────────────────
  Stream<List<AgendaModel>> watchAgenda({DateTime? from, DateTime? to}) {
    Query q = _db.collection(AppConstants.colAgenda);
    if (from != null)
      q = q.where(
        'dateDebut',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    if (to != null)
      q = q.where('dateDebut', isLessThanOrEqualTo: Timestamp.fromDate(to));
    return q
        .orderBy('dateDebut')
        .snapshots()
        .map((s) => s.docs.map(AgendaModel.fromFirestore).toList());
  }

  Future<String> addAgendaEvent(AgendaModel a) async {
    final ref = await _db
        .collection(AppConstants.colAgenda)
        .add(a.toFirestore());
    return ref.id;
  }

  Future<void> updateAgendaEvent(AgendaModel a) async {
    await _db
        .collection(AppConstants.colAgenda)
        .doc(a.id)
        .update(a.toFirestore());
  }

  Future<void> deleteAgendaEvent(String id) async {
    await _db.collection(AppConstants.colAgenda).doc(id).delete();
  }

  // ─── Dashboard Stats ─────────────────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _db.collection(AppConstants.colEmployees).count().get(),
      _db
          .collection(AppConstants.colEmployees)
          .where('statut', isEqualTo: 'actif')
          .count()
          .get(),
      _db
          .collection(AppConstants.colAttendance)
          .where('dateStr', isEqualTo: today)
          .where('statut', isEqualTo: 'present')
          .count()
          .get(),
      _db
          .collection(AppConstants.colLeaves)
          .where('statut', isEqualTo: 'approuvé')
          .count()
          .get(),
      _db
          .collection(AppConstants.colContracts)
          .where('statut', isEqualTo: 'actif')
          .count()
          .get(),
      _db
          .collection(AppConstants.colLeaves)
          .where('statut', isEqualTo: 'en_attente')
          .count()
          .get(),
    ]);

    return {
      'totalEmployes': results[0].count ?? 0,
      'employes_actifs': results[1].count ?? 0,
      'presents_aujourd_hui': results[2].count ?? 0,
      'en_conge': results[3].count ?? 0,
      'contrats_actifs': results[4].count ?? 0,
      'conges_en_attente': results[5].count ?? 0,
    };
  }

  Future<List<EmployeeModel>> getBirthdaysThisMonth() async {
    final month = DateTime.now().month;
    final snap = await _db.collection(AppConstants.colEmployees).get();
    return snap.docs
        .map(EmployeeModel.fromFirestore)
        .where((e) => e.dateNaissance.month == month)
        .toList();
  }
}
