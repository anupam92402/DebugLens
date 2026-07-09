// Barrel for the JSON viewer — the engine plus each widget in its own file.
// Consumers keep importing `widgets/json_view.dart`.
export 'json_engine.dart'
    show prettyJson, jsonMatchCount, JsonSearch, JsonViewMode;
export 'json_object_tree.dart' show JsonObjectTree;
export 'json_raw_view.dart' show JsonView;
export 'json_viewer.dart' show JsonViewer;
