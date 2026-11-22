/// Display-only tax uplift (مالیات بر ارزش افزوده) for the prices and range
/// tabs. Off by default, percent defaults to 13. Stored quotes never change:
/// the source's own announced amount stays exactly as written — only the
/// rendered تومان figure is uplifted while the switch is on.
class TaxPolicy {
  static bool enabled = false;
  static double percent = 13;

  static double apply(double v) => enabled ? v * (1 + percent / 100) : v;

  static double? applyMaybe(double? v) => v == null ? null : apply(v);
}
