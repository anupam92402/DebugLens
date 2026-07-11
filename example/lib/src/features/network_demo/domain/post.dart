import 'package:equatable/equatable.dart';

/// A jsonplaceholder post (pure model).
class Post extends Equatable {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: (json['id'] as num?)?.toInt() ?? 0,
    userId: (json['userId'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  @override
  List<Object> get props => [id, userId, title, body];
}
