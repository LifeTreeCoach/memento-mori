import LifeCore
import SwiftUI

/// Draws a life grid filling the offered space (week grid or year strip), centred.
struct LifeGridView: View {
    enum Kind { case weeks, yearStrip }

    let kind: Kind
    let calc: LifeCalculator
    let palette: LifePalette
    let accessibilityText: String

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Canvas { context, size in
            let geometry = geometry(in: size)
            let offset = CGPoint(
                x: (size.width - geometry.size.width) / 2,
                y: (size.height - geometry.size.height) / 2
            )
            draw(geometry, offset: offset, in: &context)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func geometry(in size: CGSize) -> LifeGridGeometry {
        switch kind {
        case .weeks: return .weekGrid(calc, in: size)
        case .yearStrip: return .yearStrip(calc, in: size)
        }
    }

    /// Collects the cells into one path per colour layer (lived, current, remaining) and fills
    /// each once instead of issuing thousands of individual fills.
    private func draw(_ geometry: LifeGridGeometry, offset: CGPoint, in context: inout GraphicsContext) {
        let cellWidth = geometry.pitchX * (1 - LifeGridGeometry.gapRatio)
        let cellHeight = geometry.pitchY * (1 - LifeGridGeometry.gapRatio)
        let radius = min(cellWidth, cellHeight) / 3
        var layers: [LifeGridGeometry.Cell: Path] = [.lived: Path(), .current: Path(), .remaining: Path()]
        for index in 0..<geometry.cells {
            let rect = pixelAligned(CGRect(
                x: offset.x + geometry.originX + CGFloat(index % geometry.columns) * geometry.pitchX,
                y: offset.y + CGFloat(index / geometry.columns) * geometry.pitchY,
                width: cellWidth, height: cellHeight
            ))
            layers[geometry.cell(at: index)]!.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
        }
        context.fill(layers[.lived]!, with: .color(palette.lived.color))
        context.fill(layers[.current]!, with: .color(palette.current.color))
        context.fill(layers[.remaining]!, with: .color(palette.remaining.color))
        var ticks = Path()
        addDecadeTicks(geometry, offset: offset, to: &ticks)
        context.fill(ticks, with: .color(palette.lived.color))
    }

    /// Snaps edges to device pixels so tiny week cells stay crisp instead of blurring into seams.
    private func pixelAligned(_ rect: CGRect) -> CGRect {
        let scale = max(displayScale, 1)
        func snap(_ value: CGFloat) -> CGFloat { (value * scale).rounded() / scale }
        let minX = snap(rect.minX), minY = snap(rect.minY)
        let maxX = max(snap(rect.maxX), minX + 1 / scale), maxY = max(snap(rect.maxY), minY + 1 / scale)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Short marks left of every tenth year row (age 10, 20, ...), in the lived colour.
    private func addDecadeTicks(_ geometry: LifeGridGeometry, offset: CGPoint, to path: inout Path) {
        guard geometry.tickColumns > 0 else { return }
        let thickness = max(geometry.pitchY * 0.3, 1)
        let right = offset.x + geometry.originX - geometry.pitchX * 0.4
        for row in stride(from: LifeGridGeometry.yearsPerTick, to: geometry.rows, by: LifeGridGeometry.yearsPerTick) {
            let centerY = offset.y + CGFloat(row) * geometry.pitchY + geometry.pitchY * (1 - LifeGridGeometry.gapRatio) / 2
            path.addRect(CGRect(x: right - geometry.pitchX, y: centerY - thickness / 2, width: geometry.pitchX, height: thickness))
        }
    }
}
