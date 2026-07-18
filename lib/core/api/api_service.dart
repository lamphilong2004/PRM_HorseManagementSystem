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

  Future<Tournament> getTournamentById(String tournId) async {
    final response = await _client.get('/tournaments/$tournId');
    return Tournament.fromApi(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Race>> getRaces({int limit = 1000}) async {
    final response = await _client.get('/races?limit=$limit');
    return _extractList(response.data, 'races').map(Race.fromApi).toList();
  }

  Future<List<Horse>> getHorses() async {
    final response = await _client.get('/horses/me');
    return _extractList(response.data, null).map(Horse.fromDirect).toList();
  }

  Future<dynamic> createHorse(Map<String, dynamic> data) async {
    final response = await _client.post('/horses', data);
    return response.data;
  }

  Future<dynamic> updateHorse(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/horses/$id', data);
    return response.data;
  }

  Future<dynamic> deleteHorse(String id) async {
    final response = await _client.delete('/horses/$id');
    return response.data;
  }

  Future<List<Registration>> getOwnerRegistrations() async {
    final horses = await getHorses();
    final races = await getRaces();
    
    final myHorseIds = horses.map((h) => h.id).toSet();
    final List<Registration> allRegs = [];
    
    for (final race in races) {
      try {
        final response = await _client.get('/races/${race.id}/horses');
        final raw = response.data;
        List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = raw['horses'] ?? raw['data'] ?? [];
        } else {
          list = [];
        }
        
        for (final h in list) {
          if (h is! Map) continue;
          
          // Handle horseId as Object or String (mirrors web getRaceHorses)
          dynamic rawHorseId;
          if (h['horse'] != null && h['horse'] is Map) {
            rawHorseId = h['horse']['_id'] ?? h['horse']['id'];
          } else if (h['horseId'] != null && h['horseId'] is Map) {
            rawHorseId = h['horseId']['_id'] ?? h['horseId']['id'];
          } else {
            rawHorseId = h['horseId'] ?? h['horse'] ?? h['_id'] ?? h['id'];
          }
          final horseId = rawHorseId?.toString().trim() ?? '';
          
          if (myHorseIds.contains(horseId)) {
            final matchedHorse = horses.firstWhere((horse) => horse.id == horseId);
            
            // Get horse name from nested horse object or matched horse
            String? horseName;
            if (h['horse'] is Map) {
              horseName = h['horse']['name']?.toString();
            }
            horseName ??= matchedHorse.name;
            
            // Get status (mirrors web: registrationStatus || status || 'PENDING')
            final status = (h['registrationStatus'] ?? h['status'] ?? 'PENDING').toString();
            
            final regMap = <String, dynamic>{
              '_id': h['registrationId'] ?? h['_id'] ?? h['id'] ?? '',
              'id': h['registrationId'] ?? h['_id'] ?? h['id'] ?? '',
              'horseId': horseId,
              'horse': {'id': horseId, '_id': horseId, 'name': horseName},
              'raceId': race.id,
              'race': {'id': race.id, '_id': race.id, 'name': race.name},
              'status': status,
              'confirmedByOwner': h['confirmedByOwner'],
              'rejectionReason': h['rejectionReason'],
              'jockeyId': h['jockeyId'],
              'jockey': h['jockey'],
            };
            allRegs.add(Registration.fromApi(regMap));
          }
        }
      } catch (e) {
        // Ignore individual race errors
      }
    }
    return allRegs;
  }

  Future<dynamic> confirmRaceParticipation(String horseId, String raceId) async {
    final response = await _client.patch('/horses/me/$horseId/confirm-race/$raceId');
    return response.data;
  }


  Future<dynamic> sendJockeyInvitation(String jockeyId, String horseId, String raceId, {String? registrationId}) async {
    try {
      final response = await _client.post('/horses/$horseId/invitations', {
        'jockeyId': jockeyId,
        'raceId': raceId,
        'message': 'Mời bạn cưỡi ngựa của tôi',
      });
      return response.data;
    } catch (e) {
      if (registrationId != null) {
        // Fallback to registrationId if raceId fails (e.g. 404 Race not found)
        try {
          final res2 = await _client.post('/horses/$horseId/invitations', {
            'jockeyId': jockeyId,
            'raceId': registrationId,
            'message': 'Mời bạn cưỡi ngựa của tôi',
          });
          return res2.data;
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchJockeys(String? query) async {
    String path = '/jockeys?limit=100&status=AVAILABLE';
    if (query != null && query.isNotEmpty) path += '&search=$query';
    final response = await _client.get(path);
    var list = _extractList(response.data, 'jockeys');
    if (list.isEmpty) list = _extractList(response.data, 'data');
    if (list.isEmpty) list = _extractList(response.data, null);
    return list;
  }

  Future<List<Map<String, dynamic>>> getAvailableJockeys() async {
    final response = await _client.get('/jockeys?limit=100&status=AVAILABLE');
    var list = _extractList(response.data, 'jockeys');
    if (list.isEmpty) list = _extractList(response.data, 'data');
    if (list.isEmpty) list = _extractList(response.data, null);
    return list;
  }

  Future<dynamic> registerHorseForRace(String raceId, String horseId, String jockeyId) async {
    final response = await _client.post('/registrations', {
      'raceId': raceId,
      'horseId': horseId,
      'jockeyId': jockeyId,
    });
    return response.data;
  }

  Future<dynamic> registerHorseForTournament(String tournamentId, String horseId) async {
    final response = await _client.post('/tournaments/$tournamentId/register', {
      'horseId': horseId,
    });
    return response.data;
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
    return _extractList(response.data, 'data').map(Race.fromDirect).toList();
  }

  Future<Map<String, dynamic>> getJockeyRaceDetail(String raceId) async {
    final response = await _client.get('/jockeys/me/races/$raceId');
    return Map<String, dynamic>.from(response.data as Map);
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
    dynamic raw = data;
    if (data is Map) {
      if (envelopeKey != null && data.containsKey(envelopeKey)) {
        raw = data[envelopeKey];
      } else if (data.containsKey('data')) {
        raw = data['data'];
      } else if (data.containsKey('items')) {
        raw = data['items'];
      } else if (data.containsKey('tournaments')) {
        raw = data['tournaments'];
      }
    }
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
