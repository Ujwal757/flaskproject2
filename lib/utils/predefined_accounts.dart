/// Predefined accounts for Authority and Workers
/// These accounts are fixed and cannot be registered through the signup page
class PredefinedAccounts {
  // Authority account (fixed)
  static const String authorityEmail = 'authority@roadvision.com';
  static const String authorityPassword = 'authority123';
  static const String authorityName = 'Road Authority';
  static const String authorityUserId = 'authority_user_fixed';

  // Worker accounts (at least 10 predefined)
  static final List<PredefinedWorker> workers = [
    PredefinedWorker(
      email: 'worker1@roadvision.com',
      password: 'worker123',
      name: 'Worker 1',
      userId: 'worker_1_fixed',
    ),
    PredefinedWorker(
      email: 'worker2@roadvision.com',
      password: 'worker123',
      name: 'Worker 2',
      userId: 'worker_2_fixed',
    ),
    PredefinedWorker(
      email: 'worker3@roadvision.com',
      password: 'worker123',
      name: 'Worker 3',
      userId: 'worker_3_fixed',
    ),
    PredefinedWorker(
      email: 'worker4@roadvision.com',
      password: 'worker123',
      name: 'Worker 4',
      userId: 'worker_4_fixed',
    ),
    PredefinedWorker(
      email: 'worker5@roadvision.com',
      password: 'worker123',
      name: 'Worker 5',
      userId: 'worker_5_fixed',
    ),
    PredefinedWorker(
      email: 'worker6@roadvision.com',
      password: 'worker123',
      name: 'Worker 6',
      userId: 'worker_6_fixed',
    ),
    PredefinedWorker(
      email: 'worker7@roadvision.com',
      password: 'worker123',
      name: 'Worker 7',
      userId: 'worker_7_fixed',
    ),
    PredefinedWorker(
      email: 'worker8@roadvision.com',
      password: 'worker123',
      name: 'Worker 8',
      userId: 'worker_8_fixed',
    ),
    PredefinedWorker(
      email: 'worker9@roadvision.com',
      password: 'worker123',
      name: 'Worker 9',
      userId: 'worker_9_fixed',
    ),
    PredefinedWorker(
      email: 'worker10@roadvision.com',
      password: 'worker123',
      name: 'Worker 10',
      userId: 'worker_10_fixed',
    ),
  ];

  /// Get worker by email
  static PredefinedWorker? getWorkerByEmail(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    try {
      return workers.firstWhere(
        (worker) => worker.email.toLowerCase() == normalizedEmail,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if email is a predefined account
  static bool isPredefinedAccount(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail == authorityEmail) return true;
    return workers.any(
      (worker) => worker.email.toLowerCase() == normalizedEmail,
    );
  }
}

class PredefinedWorker {
  final String email;
  final String password;
  final String name;
  final String userId;

  const PredefinedWorker({
    required this.email,
    required this.password,
    required this.name,
    required this.userId,
  });
}

