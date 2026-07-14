import '../models/app_models.dart';
import 'api_client.dart';

class ApiService {
  const ApiService(this._client);

  final ApiClient _client;

  Future<Session> login({
    required String email,
    required String password,
    required Role role,
  }) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final session = Session(
      token: data['accessToken'].toString(),
      user: User(
        id: user['userId'].toString(),
        name: user['fullName'].toString(),
        role: Role.fromString(user['role']),
        email: email,
      ),
    );
    _client.setAccessToken(session.token);
    return session;
  }

  Future<Session> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    await _client.post('/auth/register', {
      'email': email,
      'password': password,
      'fullName': name,
      'role': role.value,
    });
    return login(email: email, password: password, role: role);
  }

  Future<List<Tournament>> getTournaments() async {
    final response = await _client.get('/tournaments');
    return _extractList(
      response.data,
      'tournaments',
    ).map(Tournament.fromApi).toList();
  }

  Future<List<Race>> getRaces({int limit = 1000}) async {
    final response = await _client.get('/races?limit=$limit');
    return _extractList(response.data, 'races').map(Race.fromApi).toList();
  }

  Future<List<Horse>> getHorses() async {
    final response = await _client.get('/horses/me');
    return _extractList(response.data, null).map(Horse.fromDirect).toList();
  }

  Future<List<Invite>> getInvites() async {
    final response = await _client.get('/jockeys/me/invitations');
    return _extractList(
      response.data,
      'invitations',
    ).map(Invite.fromDirect).toList();
  }

  Future<dynamic> acceptInvitation(String inviteId) async {
    final response = await _client.patch('/jockeys/me/invitations/$inviteId/accept');
    return response.data;
  }

  Future<dynamic> rejectInvitation(String inviteId) async {
    final response = await _client.patch('/jockeys/me/invitations/$inviteId/reject');
    return response.data;
  }

  Future<List<Race>> getJockeyRaces() async {
    final response = await _client.get('/jockeys/me/races');
    return _extractList(response.data, null).map(Race.fromDirect).toList();
  }

  Future<List<Prediction>> getPredictions() async {
    final response = await _client.get('/me/predictions');
    return _extractList(
      response.data,
      'predictions',
    ).map(Prediction.fromApi).toList();
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _client.get('/auth/me');
    final data = response.data;
    return Map<String, dynamic>.from(
      (data is Map && data.containsKey('data')) ? data['data'] : data
    );
  }

  Future<Map<String, dynamic>> resetPoints() async {
    final response = await _client.post('/auth/reset-points', {});
    final data = response.data;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<AdminUser>> getAdminUsers() async {
    final response = await _client.get('/admin/users');
    return _extractList(
      response.data,
      'data',
    ).map(AdminUser.fromDirect).toList();
  }

  Future<dynamic> updateUserRole(String userId, String role) async {
    final response = await _client.patch('/admin/users/$userId/role', {'role': role});
    return response.data;
  }

  Future<List<Race>> getRefereeRaces() async {
    final response = await _client.get('/referee/races');
    return _extractList(response.data, null).map(Race.fromDirect).toList();
  }

  Future<List<Map<String, dynamic>>> getRefereeRaceHorses(String raceId) async {
    final response = await _client.get('/referee/races/$raceId/horses');
    return _extractList(response.data, 'horses');
  }

  Future<dynamic> createViolation(String raceId, Map<String, dynamic> data) async {
    final response = await _client.post('/referee/races/$raceId/violations', data);
    return response.data;
  }

  Future<dynamic> confirmRaceResult(String raceId, List<dynamic> rankings, String notes) async {
    final response = await _client.post('/referee/races/$raceId/confirm-result', {
      'rankings': rankings,
      'notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkRaceOpenForPrediction(String raceId) async {
    final response = await _client.get('/races/$raceId/predictions/open');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<dynamic> placePrediction({
    required String raceId,
    required String horseId,
    required int betAmount,
    int? predictedPosition,
  }) async {
    final body = {
      'horseId': horseId,
      'betAmount': betAmount,
    };
    if (predictedPosition != null && predictedPosition > 0) {
      body['predictedPosition'] = predictedPosition;
    }
    
    final response = await _client.post(
      '/races/$raceId/predictions',
      body,
    );
    return response.data;
  }

  Future<dynamic> closePredictions(String raceId) async {
    final response = await _client.post('/admin/races/$raceId/predictions/close', {});
    return response.data;
  }

  Future<dynamic> settlePredictions(String raceId) async {
    final response = await _client.post('/admin/races/$raceId/predictions/settle', {});
    return response.data;
  }

  Future<List<RaceHorse>> getRaceHorses(String raceId) async {
    final response = await _client.get('/races/$raceId/horses');
    return _extractList(
      response.data,
      'horses',
    ).map(RaceHorse.fromRaceEntry).toList();
  }

  Future<Map<String, dynamic>> getRaceResults(String raceId) async {
    final response = await _client.get('/results/races/$raceId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _client.get('/me/notifications');
    final data = response.data;
    final list = data is Map<String, dynamic>
        ? data['notifications'] ?? data
        : data;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getTournamentLeaderboard(
    String tournamentId,
  ) async {
    final response = await _client.get(
      '/tournaments/$tournamentId/leaderboard',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  List<Map<String, dynamic>> _extractList(dynamic data, String? envelopeKey) {
    final raw = data is Map && envelopeKey != null
        ? data[envelopeKey] ?? data
        : data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
