// ─── FILE: lib/services/firestore_service.dart ───────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_stats.dart';
import '../models/interview_session.dart';
import '../models/interview_category.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Stats ──────────────────────────────────
  Future<UserStats> getUserStats(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('summary')
        .get();
    if (doc.exists && doc.data() != null) {
      return UserStats.fromMap(doc.data()!);
    }
    return const UserStats();
  }

  Future<void> updateUserStats(String uid, UserStats stats) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('summary')
        .set(stats.toMap(), SetOptions(merge: true));
  }

  // ─── Interviews ──────────────────────────────────
  Future<List<InterviewSession>> getRecentInterviews(String uid,
      {int limit = 3}) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('interviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => InterviewSession.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<InterviewSession>> getAllInterviews(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('interviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InterviewSession.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> saveInterview(String uid, InterviewSession session) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('interviews')
        .doc(session.id.isEmpty ? null : session.id);
    await docRef.set(session.toMap());
  }

  Future<void> updateInterviewScore(
      String uid, String interviewId, double score) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('interviews')
        .doc(interviewId);
    await docRef.update({'score': score});
  }

  // ─── Categories ──────────────────────────────────
  Stream<List<InterviewCategory>> getCategories() {
    return _db.collection('interview_categories').snapshots().map(
          (snap) => snap.docs
              .map((d) => InterviewCategory.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> seedCategories() async {
    final snap = await _db.collection('interview_categories').limit(1).get();
    if (snap.docs.isNotEmpty) return; // Already seeded

    final categories = [
      {
        'title': 'Frontend Development',
        'description':
            'Master React, CSS, JavaScript, HTML, and modern frontend frameworks.',
        'icon': 'web',
        'color': '#6366F1',
        'difficulty': 'Intermediate',
        'totalQuestions': 50,
        'estimatedMinutes': 20,
      },
      {
        'title': 'Backend Development',
        'description':
            'APIs, databases, system design, Node.js, Python, and server architecture.',
        'icon': 'dns',
        'color': '#10B981',
        'difficulty': 'Intermediate',
        'totalQuestions': 50,
        'estimatedMinutes': 25,
      },
      {
        'title': 'Data Science & ML',
        'description':
            'Python, statistics, machine learning concepts, and data analysis techniques.',
        'icon': 'analytics',
        'color': '#F59E0B',
        'difficulty': 'Advanced',
        'totalQuestions': 40,
        'estimatedMinutes': 30,
      },
      {
        'title': 'DevOps & Cloud',
        'description':
            'Docker, CI/CD pipelines, Kubernetes, AWS/GCP fundamentals.',
        'icon': 'cloud',
        'color': '#0EA5E9',
        'difficulty': 'Advanced',
        'totalQuestions': 35,
        'estimatedMinutes': 25,
      },
      {
        'title': 'Behavioral / HR',
        'description':
            'STAR method, soft skills, leadership, teamwork, and communication.',
        'icon': 'people',
        'color': '#EC4899',
        'difficulty': 'Beginner',
        'totalQuestions': 30,
        'estimatedMinutes': 15,
      },
      {
        'title': 'System Design',
        'description':
            'Scalability, architecture patterns, distributed systems, and design.',
        'icon': 'architecture',
        'color': '#8B5CF6',
        'difficulty': 'Advanced',
        'totalQuestions': 25,
        'estimatedMinutes': 40,
      },
    ];

    final batch = _db.batch();
    for (final cat in categories) {
      final ref = _db.collection('interview_categories').doc();
      batch.set(ref, cat);
    }
    await batch.commit();
  }

  // ─── Quotes ──────────────────────────────────────
  Future<Map<String, String>> getRandomQuote() async {
    try {
      final snap = await _db.collection('quotes').get();
      if (snap.docs.isEmpty) {
        // Seed default quotes
        await _seedQuotes();
        return {
          'text': 'The secret of getting ahead is getting started.',
          'author': 'Mark Twain',
        };
      }
      final idx = DateTime.now().millisecondsSinceEpoch % snap.docs.length;
      final data = snap.docs[idx].data();
      return {
        'text': data['text'] as String? ?? '',
        'author': data['author'] as String? ?? '',
      };
    } catch (_) {
      return {
        'text': 'The secret of getting ahead is getting started.',
        'author': 'Mark Twain',
      };
    }
  }

  Future<void> _seedQuotes() async {
    final quotes = [
      {
        'text': 'The secret of getting ahead is getting started.',
        'author': 'Mark Twain'
      },
      {
        'text': 'Success is where preparation and opportunity meet.',
        'author': 'Bobby Unser'
      },
      {
        'text': 'Do something today that your future self will thank you for.',
        'author': 'Sean Patrick Flanery'
      },
      {
        'text': 'The expert in anything was once a beginner.',
        'author': 'Helen Hayes'
      },
      {
        'text': 'Believe you can and you\'re halfway there.',
        'author': 'Theodore Roosevelt'
      },
    ];
    final batch = _db.batch();
    for (final q in quotes) {
      batch.set(_db.collection('quotes').doc(), q);
    }
    await batch.commit();
  }

  // ─── User Profile & Preferences ──────────────────
  Future<void> updateUserProfile(String uid, String displayName) async {
    await _db.collection('users').doc(uid).set(
      {'displayName': displayName},
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserPreferences(
      String uid, Map<String, dynamic> prefs) async {
    await _db.collection('users').doc(uid).set(
      {'preferences': prefs},
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Delete User Data ─────────────────────────────
  Future<void> deleteUserData(String uid) async {
    final interviewsSnap =
        await _db.collection('users').doc(uid).collection('interviews').get();
    final batch = _db.batch();
    for (final doc in interviewsSnap.docs) {
      batch.delete(doc.reference);
    }
    final statsRef =
        _db.collection('users').doc(uid).collection('stats').doc('summary');
    batch.delete(statsRef);
    batch.delete(_db.collection('users').doc(uid));
    await batch.commit();
  }

  // ─── Groq Question Cache ─────────────────────────
  Future<void> cacheGeneratedQuestions(
    String categoryId,
    List<Map<String, dynamic>> questions,
  ) async {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    await _db
        .collection('interview_categories')
        .doc(categoryId)
        .collection('generated_questions')
        .doc(ts)
        .set({
      'questions': questions,
      'generatedAt': FieldValue.serverTimestamp()
    });
  }
}
