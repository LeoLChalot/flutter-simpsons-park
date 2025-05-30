class Character {
  final String firstName;
  final String lastName;
  final String pseudo;
  final String imageUrl;
  final String history;

  Character({
    required this.firstName,
    required this.lastName,
    required this.pseudo,
    required this.imageUrl,
    required this.history,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName'];
    final lastName = json['lastName'];
    final pseudo = json['pseudo'];
    final imageUrl = json['imageUrl'];
    final history = json['history'];

    return Character(
      firstName: firstName,
      lastName: lastName,
      pseudo: pseudo,
      imageUrl: imageUrl,
      history: history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'pseudo': pseudo,
      'imageUrl': imageUrl,
      'history': history,
    };
  }
}
