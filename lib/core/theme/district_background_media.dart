/// Declares what media (if any) backs a district's atmosphere backdrop,
/// decoupling that choice from the widget that renders it -- so swapping
/// a district between a placeholder still image and a looping video (or
/// later, commissioned final art in either form) is a one-line config
/// change, not a widget rewrite.
sealed class DistrictBackgroundMedia {
  const DistrictBackgroundMedia();
}

/// A single static image asset, rendered cover-fit.
class DistrictImageBackground extends DistrictBackgroundMedia {
  final String assetPath;

  const DistrictImageBackground(this.assetPath);
}

/// A looping, muted video asset, rendered cover-fit.
class DistrictVideoBackground extends DistrictBackgroundMedia {
  final String assetPath;

  const DistrictVideoBackground(this.assetPath);
}
