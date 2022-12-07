abstract class User {
  Future<String> getIdToken(forceRefresh) {
    throw 'Not implemented on web';
  }

  String get uid {
    throw 'Not implemented on web';
  }
}

class FirebaseAuthException {}
