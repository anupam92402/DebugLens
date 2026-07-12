/// Immutable set membership toggle, shared by the filter-chip rows.
extension SetToggle<T> on Set<T> {
  /// Returns a copy of this set with [value] removed if present, else added.
  Set<T> toggled(T value) {
    final next = Set<T>.of(this);
    if (!next.add(value)) next.remove(value);
    return next;
  }
}
