import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/predefined_accounts.dart';

class AuthService {
  late final DatabaseReference _database;
  AppUser? _currentUser;
  static const String _currentUserIdKey = 'current_user_id';
  
  // Fixed admin credentials
  static const String _adminEmail = 'admin@roadvision.com';
  static const String _adminPassword = 'admin123';
  static const String _adminName = 'System Administrator';
  static const String _adminUserId = 'admin_user_fixed';

  AuthService() {
    // Initialize database with explicit URL from firebase_options
    _database = FirebaseDatabase.instance.ref();
  }

  // Get current user
  AppUser? get currentUser => _currentUser;

  // Initialize - load current user from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserIdKey);
      if (userId != null && userId.isNotEmpty) {
        await _loadUser(userId);
      }
    } catch (e) {
      print('Error initializing auth: $e');
    }
  }

  // Load user from database
  Future<void> _loadUser(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        _currentUser = AppUser.fromMap(data);
      }
    } catch (e) {
      print('Error loading user: $e');
      _currentUser = null;
    }
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register with email and password
  /// Only allows citizen registration. Authority and Worker accounts are predefined.
  Future<AppUser> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      print('🔵 Starting registration for: $email');
      final normalizedEmail = email.toLowerCase().trim();
      
      // Only allow citizen registration
      if (role != UserRole.citizen) {
        throw Exception('Only citizens can register. Authority and Worker accounts are predefined. Please contact your administrator for access.');
      }
      
      // Prevent registration with admin email
      if (normalizedEmail == _adminEmail) {
        throw Exception('This email is reserved for system administration. Please use a different email.');
      }
      
      // Prevent registration with predefined accounts (authority and workers)
      if (PredefinedAccounts.isPredefinedAccount(normalizedEmail)) {
        throw Exception('This email is reserved for a predefined account. Please use a different email or contact your administrator.');
      }
      
      // Check if email already exists
      // Try using orderByChild query first
      try {
        print('🔵 Checking if email exists: $normalizedEmail');
        final emailSnapshot = await _database
            .child('users')
            .orderByChild('email')
            .equalTo(normalizedEmail)
            .get();

        if (emailSnapshot.exists && emailSnapshot.value != null) {
          print('⚠️ Email already exists in database');
          throw Exception('An account already exists for that email. Please use a different email or try logging in.');
        }
        print('✅ Email is available');
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        // If orderByChild fails (e.g., missing index, permission, etc.), try checking all users
        if (errorStr.contains('index') || errorStr.contains('permission') || 
            errorStr.contains('network') || errorStr.contains('timeout')) {
          // Fallback: Get all users and check manually
          print('⚠️ Email query failed, using fallback method: ${e.toString()}');
          try {
            final allUsersSnapshot = await _database.child('users').get();
            if (allUsersSnapshot.exists && allUsersSnapshot.value != null) {
              final allUsers = allUsersSnapshot.value as Map<dynamic, dynamic>;
              for (var userEntry in allUsers.entries) {
                final userData = userEntry.value as Map<dynamic, dynamic>;
                final userEmail = (userData['email'] ?? '').toString().toLowerCase().trim();
                if (userEmail == normalizedEmail) {
                  throw Exception('An account already exists for that email. Please use a different email or try logging in.');
                }
              }
            }
            print('✅ Email check completed (fallback method)');
          } catch (fallbackError) {
            // If the fallback also fails, only rethrow if it's an "already exists" error
            if (fallbackError.toString().contains('already exists')) {
              rethrow;
            }
            // Otherwise, log and continue (registration will proceed)
            print('⚠️ Fallback email check also failed, continuing registration: $fallbackError');
          }
        } else if (errorStr.contains('already exists')) {
          // Re-throw "already exists" errors
          rethrow;
        } else {
          // For other errors (like network issues), log and continue
          // The database write will fail later if there's a real issue
          print('⚠️ Email check error (continuing): ${e.toString()}');
        }
      }

      // Generate user ID
      final userId = _database.child('users').push().key!;

      // Hash password
      final passwordHash = _hashPassword(password);

      // Create user object (always citizen role)
      final appUser = AppUser(
        id: userId,
        email: normalizedEmail,
        name: name.trim(),
        passwordHash: passwordHash,
        role: UserRole.citizen,
        createdAt: DateTime.now(),
      );

      // Save to database (include password hash)
      print('🔵 Saving user to database: $userId');
      await _database.child('users').child(userId).set(appUser.toMap(includePassword: true));
      print('✅ User saved successfully');

      // Set as current user
      _currentUser = appUser;

      // Save user ID to local storage (with error handling for web)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserIdKey, userId);
        print('✅ User ID saved to local storage');
      } catch (e) {
        print('⚠️ Warning: Could not save to local storage: $e');
        // Continue anyway - the user is still set in memory
      }
      
      print('✅ Registration completed for: $normalizedEmail');

      return appUser;
    } catch (e) {
      print('❌ Registration error: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      // Check for fixed admin credentials first
      if (normalizedEmail == _adminEmail && password == _adminPassword) {
        // Admin credentials match - create or load admin user
        return await _signInAsAdmin();
      }
      
      // Check for predefined authority account
      if (normalizedEmail == PredefinedAccounts.authorityEmail && 
          password == PredefinedAccounts.authorityPassword) {
        return await _signInAsAuthority();
      }
      
      // Check for predefined worker accounts
      final worker = PredefinedAccounts.getWorkerByEmail(normalizedEmail);
      if (worker != null && password == worker.password) {
        return await _signInAsWorker(worker);
      }
      
      // Find user by email in database
      String? userId;
      Map<String, dynamic>? userData;

      // Try using orderByChild query first
      try {
        final emailSnapshot = await _database
            .child('users')
            .orderByChild('email')
            .equalTo(normalizedEmail)
            .get();

        if (!emailSnapshot.exists || emailSnapshot.value == null) {
          throw Exception('No user found for that email. Please check your email or register.');
        }

        // Get user data (orderByChild returns a map with userId as key)
        final data = emailSnapshot.value as Map<dynamic, dynamic>;
        
        // Find the user (there should be only one)
        data.forEach((key, value) {
          if (value is Map) {
            final userMap = Map<String, dynamic>.from(value);
            final userEmail = (userMap['email'] ?? '').toString().toLowerCase().trim();
            if (userEmail == normalizedEmail) {
              userId = key.toString();
              userData = userMap;
            }
          }
        });
      } catch (e) {
        // If orderByChild fails (e.g., missing index), try checking all users
        if (e.toString().contains('index') || e.toString().contains('Index') || 
            e.toString().contains('No user found')) {
          // Fallback: Get all users and check manually
          print('⚠️ Email index not available, using fallback method for login...');
          final allUsersSnapshot = await _database.child('users').get();
          
          if (!allUsersSnapshot.exists || allUsersSnapshot.value == null) {
            throw Exception('No user found for that email. Please check your email or register.');
          }
          
          final allUsers = allUsersSnapshot.value as Map<dynamic, dynamic>;
          bool found = false;
          
          for (var userEntry in allUsers.entries) {
            final userMap = userEntry.value as Map<dynamic, dynamic>;
            final userEmail = (userMap['email'] ?? '').toString().toLowerCase().trim();
            if (userEmail == normalizedEmail) {
              userId = userEntry.key.toString();
              userData = Map<String, dynamic>.from(userMap);
              found = true;
              break;
            }
          }
          
          if (!found) {
            throw Exception('No user found for that email. Please check your email or register.');
          }
        } else {
          // Re-throw if it's not an index error or "no user found" error
          rethrow;
        }
      }

      if (userId == null || userData == null) {
        throw Exception('User not found. Please check your email.');
      }

      // Verify password (userData is guaranteed to be non-null here)
      final storedPasswordHash = userData!['passwordHash'];
      if (storedPasswordHash == null || storedPasswordHash is! String) {
        throw Exception('Invalid user data. Please contact support.');
      }

      final inputPasswordHash = _hashPassword(password);
      if (inputPasswordHash != storedPasswordHash) {
        throw Exception('Wrong password. Please try again.');
      }

      // Create user object (without password hash)
      final appUser = AppUser.fromMap(userData!);

      // Set as current user
      _currentUser = appUser;

      // Save user ID to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, userId!);

      return appUser;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  /// Get current user's role
  UserRole? getCurrentUserRole() {
    return _currentUser?.role;
  }

  /// Get current user's AppUser object
  AppUser? getCurrentAppUser() {
    return _currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Sign in as admin with fixed credentials
  Future<AppUser> _signInAsAdmin() async {
    try {
      // Check if admin user exists in database
      final adminSnapshot = await _database.child('users').child(_adminUserId).get();
      
      AppUser adminUser;
      
      if (adminSnapshot.exists) {
        // Admin exists, load from database
        final data = Map<String, dynamic>.from(adminSnapshot.value as Map<dynamic, dynamic>);
        adminUser = AppUser.fromMap(data);
      } else {
        // Admin doesn't exist, create it
        final passwordHash = _hashPassword(_adminPassword);
        adminUser = AppUser(
          id: _adminUserId,
          email: _adminEmail,
          name: _adminName,
          passwordHash: passwordHash,
          role: UserRole.authority,
          createdAt: DateTime.now(),
        );
        
        // Save admin to database
        await _database.child('users').child(_adminUserId).set(
          adminUser.toMap(includePassword: true),
        );
      }
      
      // Set as current user
      _currentUser = adminUser;
      
      // Save user ID to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, _adminUserId);
      
      return adminUser;
    } catch (e) {
      throw Exception('Admin login failed: ${e.toString()}');
    }
  }

  /// Sign in as authority with predefined credentials
  Future<AppUser> _signInAsAuthority() async {
    try {
      // Check if authority user exists in database
      final authoritySnapshot = await _database.child('users').child(PredefinedAccounts.authorityUserId).get();
      
      AppUser authorityUser;
      
      if (authoritySnapshot.exists) {
        // Authority exists, load from database
        final data = Map<String, dynamic>.from(authoritySnapshot.value as Map<dynamic, dynamic>);
        authorityUser = AppUser.fromMap(data);
      } else {
        // Authority doesn't exist, create it
        final passwordHash = _hashPassword(PredefinedAccounts.authorityPassword);
        authorityUser = AppUser(
          id: PredefinedAccounts.authorityUserId,
          email: PredefinedAccounts.authorityEmail,
          name: PredefinedAccounts.authorityName,
          passwordHash: passwordHash,
          role: UserRole.authority,
          createdAt: DateTime.now(),
        );
        
        // Save authority to database
        await _database.child('users').child(PredefinedAccounts.authorityUserId).set(
          authorityUser.toMap(includePassword: true),
        );
      }
      
      // Set as current user
      _currentUser = authorityUser;
      
      // Save user ID to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, PredefinedAccounts.authorityUserId);
      
      return authorityUser;
    } catch (e) {
      throw Exception('Authority login failed: ${e.toString()}');
    }
  }

  /// Sign in as worker with predefined credentials
  Future<AppUser> _signInAsWorker(PredefinedWorker worker) async {
    try {
      // Check if worker user exists in database
      final workerSnapshot = await _database.child('users').child(worker.userId).get();
      
      AppUser workerUser;
      
      if (workerSnapshot.exists) {
        // Worker exists, load from database
        final data = Map<String, dynamic>.from(workerSnapshot.value as Map<dynamic, dynamic>);
        workerUser = AppUser.fromMap(data);
      } else {
        // Worker doesn't exist, create it
        final passwordHash = _hashPassword(worker.password);
        workerUser = AppUser(
          id: worker.userId,
          email: worker.email,
          name: worker.name,
          passwordHash: passwordHash,
          role: UserRole.worker,
          createdAt: DateTime.now(),
        );
        
        // Save worker to database
        await _database.child('users').child(worker.userId).set(
          workerUser.toMap(includePassword: true),
        );
      }
      
      // Set as current user
      _currentUser = workerUser;
      
      // Save user ID to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, worker.userId);
      
      return workerUser;
    } catch (e) {
      throw Exception('Worker login failed: ${e.toString()}');
    }
  }
}
