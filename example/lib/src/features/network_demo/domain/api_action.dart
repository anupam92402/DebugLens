/// The one-shot API calls the playground runs inline (result shown on the
/// tile). The posts GET is handled separately because it opens a screen.
enum ApiAction { catFact, createPost, updatePost, deletePost, missingPost }

extension ApiActionInfo on ApiAction {
  String get title => switch (this) {
    ApiAction.catFact => 'Random cat fact',
    ApiAction.createPost => 'Create post',
    ApiAction.updatePost => 'Update post',
    ApiAction.deletePost => 'Delete post',
    ApiAction.missingPost => 'Missing post (404)',
  };

  String get subtitle => switch (this) {
    ApiAction.catFact => 'GET catfact.ninja/fact',
    ApiAction.createPost => 'POST jsonplaceholder /posts',
    ApiAction.updatePost => 'PUT jsonplaceholder /posts/1',
    ApiAction.deletePost => 'DELETE jsonplaceholder /posts/1',
    ApiAction.missingPost => 'GET jsonplaceholder /posts/999999',
  };

  String get methodLabel => switch (this) {
    ApiAction.catFact || ApiAction.missingPost => 'GET',
    ApiAction.createPost => 'POST',
    ApiAction.updatePost => 'PUT',
    ApiAction.deletePost => 'DELETE',
  };
}
