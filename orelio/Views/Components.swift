import SwiftUI
import UIKit

struct EmptyPrompt: View {
    let symbol: String
    let title: String
    let subtitle: String
    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(subtitle))
    }
}

struct PhotoTile: View {
    let record: PhotoRecord
    let selected: Bool
    let selecting: Bool
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = UIImage(contentsOfFile: AppFolders.thumbnail(record).path) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Rectangle().fill(.gray.opacity(0.2)).overlay { Image(systemName: "photo") }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if selecting {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title3).symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, selected ? Color.blue : Color.black.opacity(0.5))
                        .padding(7)
                }
            }
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(selected && selecting ? .blue : .clear, lineWidth: 3) }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RenderedPhoto: View {
    let record: PhotoRecord
    var activeLight: LightLayer? = nil
    var onLightMove: ((Double, Double) -> Void)? = nil
    var grid: GridSettings = GridSettings()
    @State private var rendered: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let rendered {
                    let scale = min(geometry.size.width / max(rendered.size.width, 1),
                                    geometry.size.height / max(rendered.size.height, 1))
                    let w = rendered.size.width * scale
                    let h = rendered.size.height * scale
                    // Image and its drag target share the *fitted image rectangle*.
                    // This prevents light controls leaking into letterboxing around the photo.
                    Image(uiImage: rendered)
                        .resizable()
                        .frame(width: w, height: h)
                        .overlay {
                            CompositionGridView(settings: grid,
                                outsideBorderFraction: record.recipe.borderEnabled && record.recipe.borderPlacement == .outside
                                    ? record.recipe.borderThickness : 0)
                        }
                        .overlay(alignment: .topLeading) {
                            if let activeLight, let onLightMove {
                                ZStack(alignment: .topLeading) {
                                    Circle()
                                        .fill(Color.orange.opacity(0.18))
                                        .frame(width: 42, height: 42)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                                        .overlay(Image(systemName: "plus").font(.caption.weight(.bold)))
                                        .position(x: CGFloat(activeLight.x) * w,
                                                  y: CGFloat(activeLight.y) * h)
                                }
                                .frame(width: w, height: h)
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onChanged { value in
                                        guard w > 0 && h > 0 else { return }
                                        onLightMove(
                                            min(1, max(0, Double(value.location.x / w))),
                                            min(1, max(0, Double(value.location.y / h)))
                                        )
                                    })
                            }
                        }
                        .clipped()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .accessibilityLabel("Edited image preview")
                } else {
                    ProgressView("Rendering…")
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .coordinateSpace(name: "orelio-preview")
        }
        .task(id: record) {
            // Coalesce rapid slider/drag events before starting an expensive render.
            do { try await Task.sleep(nanoseconds: 110_000_000) } catch { return }
            guard !Task.isCancelled else { return }
            let image = await Task.detached(priority: .userInitiated) {
                ImagePipeline.shared.renderPreview(record)
            }.value
            if !Task.isCancelled { rendered = image }
        }
    }
}

struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let limits: ClosedRange<Double>
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text(value.formatted(.number.precision(.fractionLength(2))))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: limits)
                .tint(Color(red: 0.773, green: 0.482, blue: 0.337))
        }
        .padding(.vertical, 2)
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let files: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: files, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ThumbnailStrip: View {
    let photos: [PhotoRecord]
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    PhotoTile(record: photo, selected: false, selecting: false)
                        .frame(width: 90, height: 90)
                }
            }.padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}
