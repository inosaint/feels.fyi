import SwiftUI

enum WeatherPalette {
    static let ink = Color(red: 0.13, green: 0.02, blue: 0.07)
}

/*
 Previous custom material-based glass implementation, preserved while we tune the
 native Liquid Glass version below.

private enum SearchTransitionGeometry {
    static let pillID = "search-pill"
}

private struct SoftPillMaterialBackground: View {
    var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .fill(WeatherPalette.ink.opacity(0.045))
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.16), lineWidth: 0.5)
            )
}
}

private struct SoftSearchControlMaterialBackground: View {
    var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .fill(.white.opacity(0.18))
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.26), lineWidth: 0.5)
            )
    }
}

extension View {
    @ViewBuilder
    func searchPillMatchedGeometry(in namespace: Namespace.ID?, isSource: Bool = true) -> some View {
        if let namespace {
            self.matchedGeometryEffect(
                id: SearchTransitionGeometry.pillID,
                in: namespace,
                isSource: isSource
            )
        } else {
            self
        }
    }

    @ViewBuilder
    func searchFieldGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self
                .background(SoftSearchControlMaterialBackground())
        }
    }

    @ViewBuilder
    func searchActionGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self
                .background(SoftSearchControlMaterialBackground())
        }
    }

    @ViewBuilder
    func locationPillGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive(), in: .capsule)
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        } else {
            self
                .background(SoftPillMaterialBackground())
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        }
    }
}
*/

private enum NativeLiquidGlassGeometry {
    static let searchPillID = "search-pill"
}

/*
 Previous tint experiment, preserved while testing pure native Liquid Glass.

private enum NativeLiquidGlassTint {
    static let searchSurface = Color.white.opacity(0.42)
    static let locationPill = Color.white.opacity(0.48)
}
*/

private struct NativePillFallbackMaterialBackground: View {
    var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
    }
}

private struct NativeSearchControlFallbackMaterialBackground: View {
    var body: some View {
        Capsule()
            .fill(Color(.secondarySystemBackground))
    }
}

private struct NativeSearchResultFallbackBackground: View {
    var body: some View {
        Capsule()
            .fill(Color(.secondarySystemBackground).opacity(0.72))
            .overlay(
                Capsule()
                    .fill(.white.opacity(0.18))
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.26), lineWidth: 0.5)
            )
    }
}

private struct NativeLiquidGlassRimLight: View {
    var body: some View {
        Capsule()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(0.65),
                        .white.opacity(0.05),
                        .white.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.75
            )
    }
}

extension View {
    @ViewBuilder
    func nativeLiquidGlassContainer(spacing: CGFloat) -> some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                self
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func nativeSearchPillGlassTransition(in namespace: Namespace.ID?) -> some View {
        if #available(iOS 26, *), let namespace {
            self.glassEffectID(NativeLiquidGlassGeometry.searchPillID, in: namespace)
        } else if let namespace {
            self.matchedGeometryEffect(
                id: NativeLiquidGlassGeometry.searchPillID,
                in: namespace
            )
        } else {
            self
        }
    }

    @ViewBuilder
    func nativeSearchFieldGlass(fallbackSearchFillOpacity: Double = 1) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear.interactive(), in: .capsule)
                /*
                 Rim light is now drawn in ContentView as a separate layer, outside
                 the GlassEffectContainer, so the search backdrop cannot cover it.
                .overlay(NativeLiquidGlassRimLight())
                 */
        } else {
            self
                .background {
                    NativePillFallbackMaterialBackground()
                    NativeSearchControlFallbackMaterialBackground()
                        .opacity(fallbackSearchFillOpacity)
                }
        }
    }

    /*
     Previous button-style attempt. It uses native Liquid Glass, but SwiftUI's
     GlassButtonStyle owns extra sizing/padding, which made the pill too large
     compared with the reference recording.

    @ViewBuilder
    func nativeSearchActionGlassButton() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            self
                .buttonStyle(.plain)
                .background(NativeSearchControlFallbackMaterialBackground())
        }
    }

    @ViewBuilder
    func nativeLocationPillGlassButton() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            self
                .buttonStyle(.plain)
                .background(NativePillFallbackMaterialBackground())
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        }
    }
    */

    @ViewBuilder
    func nativeCompactSearchActionGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear.interactive(), in: .capsule)
                /*
                 Rim light is now drawn in ContentView as a separate layer, outside
                 the GlassEffectContainer, so the search backdrop cannot cover it.
                .overlay(NativeLiquidGlassRimLight())
                 */
        } else {
            self
                .background(NativeSearchControlFallbackMaterialBackground())
        }
    }

    @ViewBuilder
    func nativeLiquidGlassRimBorder() -> some View {
        if #available(iOS 26, *) {
            self
                .overlay(NativeLiquidGlassRimLight())
        } else {
            self
        }
    }

    @ViewBuilder
    func nativeCompactLocationPillGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear.interactive(), in: .capsule)
        } else {
            self
                .background(NativePillFallbackMaterialBackground())
                .shadow(color: .black.opacity(0.16), radius: 23, x: 0, y: 18)
        }
    }

    @ViewBuilder
    func nativeSearchResultRowGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear.interactive(), in: .capsule)
        } else {
            self
                .background(NativeSearchResultFallbackBackground())
        }
    }
}
