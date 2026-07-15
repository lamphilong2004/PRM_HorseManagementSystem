import 'dart:convert';

enum Role {
  admin('ADMIN'),
  owner('OWNER'),
  jockey('JOCKEY'),
  referee('REFEREE'),
  spectator('SPECTATOR');

  const Role(this.value);

  final String value;

  static Role fromString(Object? value) {
    if (value == null) return Role.spectator;
    final normalized = value.toString().toUpperCase();
    
    if (normalized.contains('ADMIN')) return Role.admin;
    if (normalized.contains('OWNER')) return Role.owner;
    if (normalized.contains('JOCKEY') || normalized.contains('JOKEY')) return Role.jockey;
    if (normalized.contains('REFEREE')) return Role.referee;
    
    return Role.spectator;
  }
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
  });

  final String id;
  final String name;
  final Role role;
  final String? email;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.value,
    if (email != null) 'email': email,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: _stringValue(json['id']),
    name: _stringValue(json['name']),
    role: Role.fromString(json['role']),
    email: json['email']?.toString(),
  );
}

class Session {
  const Session({required this.token, required this.user});

  final String token;
  final User user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};

  String encode() => jsonEncode(toJson());

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    token: _stringValue(json['token']),
    user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );
}

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.description,
    this.prizePool,
    this.currency,
    this.maxHorses,
    this.minHorses,
    this.status,
    this.registeredCount,
    this.currentRound,
    this.totalRounds,
  });

  final String id;
  final String name;
  final String location;
  final String startDate;
  final String endDate;
  final String? description;
  final num? prizePool;
  final String? currency;
  final int? maxHorses;
  final int? minHorses;
  final String? status;
  final int? registeredCount;
  final int? currentRound;
  final int? totalRounds;

  factory Tournament.fromApi(Map<String, dynamic> json) => Tournament(
    id: _stringValue(json['_id'] ?? json['id']),
    name: _stringValue(json['name']),
    location: _stringValue(json['venue'] ?? json['location']),
    startDate: _dateOnly(json['startDate']),
    endDate: _dateOnly(json['endDate']),
    description: json['description']?.toString(),
    prizePool: json['prizePool'] is num ? json['prizePool'] as num : null,
    currency: json['currency']?.toString(),
    maxHorses: json['maxHorses'] is int ? json['maxHorses'] as int : (int.tryParse(_stringValue(json['maxHorses']))),
    minHorses: json['minHorses'] is int ? json['minHorses'] as int : (int.tryParse(_stringValue(json['minHorses']))),
    status: json['status']?.toString(),
    registeredCount: json['registeredCount'] is int ? json['registeredCount'] as int : (int.tryParse(_stringValue(json['registeredCount']))),
    currentRound: json['currentRound'] is int ? json['currentRound'] as int : (int.tryParse(_stringValue(json['currentRound']))),
    totalRounds: json['totalRounds'] is int ? json['totalRounds'] as int : (int.tryParse(_stringValue(json['totalRounds']))),
  );
}

class Race {
  const Race({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.scheduledAt,
    required this.status,
    this.distance,
    this.maxHorses,
    this.location,
    this.prizePool,
  });

  final String id;
  final String tournamentId;
  final String name;
  final String scheduledAt;
  final String status;
  final int? distance;
  final int? maxHorses;
  final String? location;
  final num? prizePool;

  factory Race.fromApi(Map<String, dynamic> json) {
    final tournament = json['tournamentId'];
    return Race(
      id: _stringValue(json['_id'] ?? json['id'] ?? json['raceId']),
      tournamentId: tournament is Map
          ? _stringValue(tournament['_id'])
          : _stringValue(tournament),
      name: _stringValue(json['name'] ?? json['raceName']),
      scheduledAt: _stringValue(json['scheduledAt'] ?? json['scheduledTime']),
      status: _stringValue(json['status']),
      distance: json['distance'] is int ? json['distance'] : (int.tryParse(_stringValue(json['distance']))),
      maxHorses: json['maxHorses'] is int ? json['maxHorses'] : (int.tryParse(_stringValue(json['maxHorses'] ?? json['maxParticipants']))),
      location: _stringValue(json['location'] ?? (tournament is Map ? tournament['venue'] ?? tournament['location'] : '')),
      prizePool: json['prizePool'] is num ? json['prizePool'] as num : null,
    );
  }

  factory Race.fromDirect(Map<String, dynamic> json) {
    final tournament = json['tournamentId'];
    return Race(
      id: _stringValue(json['_id'] ?? json['id'] ?? json['raceId']),
      tournamentId: tournament is Map
          ? _stringValue(tournament['_id'] ?? tournament['id'])
          : _stringValue(tournament),
      name: _stringValue(json['name'] ?? json['raceName']),
      scheduledAt: _stringValue(json['scheduledAt'] ?? json['scheduledTime']),
      status: _stringValue(json['status']),
      distance: json['distance'] is int ? json['distance'] : (int.tryParse(_stringValue(json['distance']))),
      maxHorses: json['maxHorses'] is int ? json['maxHorses'] : (int.tryParse(_stringValue(json['maxHorses'] ?? json['maxParticipants']))),
      location: _stringValue(json['location'] ?? (tournament is Map ? tournament['venue'] ?? tournament['location'] : '')),
      prizePool: json['prizePool'] is num ? json['prizePool'] as num : null,
    );
  }
}

class Horse {
  const Horse({required this.id, required this.name, required this.ownerId});

  final String id;
  final String name;
  final String ownerId;

  factory Horse.fromDirect(Map<String, dynamic> json) => Horse(
    id: _stringValue(json['_id'] ?? json['id']),
    name: _stringValue(json['name']),
    ownerId: _stringValue(json['ownerId']),
  );
}

class Invite {
  const Invite({
    required this.id,
    required this.horseId,
    required this.horseName,
    required this.status,
    this.ownerName,
    this.ownerEmail,
    this.message,
    this.raceName,
    this.raceDistance,
    this.raceScheduledAt,
    this.horseBreed,
    this.horseWeight,
  });

  final String id;
  final String horseId;
  final String horseName;
  final String status;
  final String? ownerName;
  final String? ownerEmail;
  final String? message;
  final String? raceName;
  final int? raceDistance;
  final String? raceScheduledAt;
  final String? horseBreed;
  final int? horseWeight;

  factory Invite.fromDirect(Map<String, dynamic> json) {
    print("DEBUG INVITE JSON: $json");
    final horse = json['horseId'];
    final race = json['raceId'];
    final owner = json['ownerId'];
    
    return Invite(
      id: _stringValue(json['_id'] ?? json['id']),
      horseId: horse is Map
          ? _stringValue(horse['_id'] ?? horse['id'])
          : _stringValue(horse),
      horseName: horse is Map
          ? _stringValue(horse['name'])
          : _stringValue(json['horseName'] ?? horse),
      status: _stringValue(json['status']),
      ownerName: owner is Map ? _stringValue(owner['fullName']) : null,
      ownerEmail: owner is Map ? _stringValue(owner['email']) : null,
      message: json['message']?.toString(),
      raceName: race is Map ? _stringValue(race['name']) : null,
      raceDistance: race is Map ? (race['distance'] is int ? race['distance'] : (int.tryParse(_stringValue(race['distance'])))) : null,
      raceScheduledAt: race is Map ? _stringValue(race['scheduledAt']) : null,
      horseBreed: horse is Map ? _stringValue(horse['breed']) : null,
      horseWeight: horse is Map ? (horse['weight'] is int ? horse['weight'] : (int.tryParse(_stringValue(horse['weight'])))) : null,
    );
  }
}

class Prediction {
  const Prediction({
    required this.id,
    required this.raceId,
    required this.pickedHorseName,
    required this.status,
    this.betAmount,
    this.prizeAmount,
    this.raceName,
    this.createdAt,
  });

  final String id;
  final String raceId;
  final String pickedHorseName;
  final String status;
  final num? betAmount;
  final num? prizeAmount;
  final String? raceName;
  final String? createdAt;

  factory Prediction.fromApi(Map<String, dynamic> json) {
    final race = json['raceId'];
    final horse = json['horseId'];
    final apiStatus = _stringValue(json['status']);
    final mappedStatus = apiStatus == 'OPEN' || apiStatus == 'CLOSED'
        ? 'PENDING'
        : apiStatus;

    return Prediction(
      id: _stringValue(json['_id'] ?? json['id']),
      raceId: race is Map
          ? _stringValue(race['_id'])
          : _stringValue(race),
      pickedHorseName: horse is Map
          ? _stringValue(horse['name'])
          : '',
      status: mappedStatus,
      betAmount: json['betAmount'] is num ? json['betAmount'] as num : null,
      prizeAmount: json['prizeAmount'] is num ? json['prizeAmount'] as num : (json['payout'] is num ? json['payout'] as num : null),
      raceName: race is Map ? _stringValue(race['name']) : '',
      createdAt: _stringValue(json['createdAt']),
    );
  }
}

class RaceHorse {
  const RaceHorse({
    required this.id, 
    required this.name,
    this.registrationId,
    this.jockeyName,
  });

  final String id;
  final String name;
  final String? registrationId;
  final String? jockeyName;

  factory RaceHorse.fromRaceEntry(Map<String, dynamic> json) {
    final horse = json['horse'];
    final horseId = json['horseId'];
    return RaceHorse(
      id: horse is Map
          ? _stringValue(horse['_id'])
          : horseId is Map
          ? _stringValue(horseId['_id'])
          : '',
      name: horse is Map
          ? _stringValue(horse['name'])
          : horseId is Map
          ? _stringValue(horseId['name'])
          : '',
      registrationId: _stringValue(json['registrationId'] ?? json['_id'] ?? json['id']),
      jockeyName: _stringValue(json['jockeyName'] ?? json['jockey']?['user']?['fullName']),
    );
  }
}

class AdminUser {
  const AdminUser({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final Role role;

  factory AdminUser.fromDirect(Map<String, dynamic> json) => AdminUser(
    id: _stringValue(json['userId'] ?? json['_id'] ?? json['id']),
    name: _stringValue(json['fullName'] ?? json['name']),
    role: Role.fromString(json['role']),
  );
}

String _dateOnly(Object? value) {
  final text = _stringValue(value);
  return text.contains('T') ? text.split('T').first : text;
}

String _stringValue(Object? value) => value?.toString() ?? '';
