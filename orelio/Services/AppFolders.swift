import Foundation

enum AppFolders {
    static var documents: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    static var originals: URL { documents.appendingPathComponent("Originals", isDirectory: true) }
    static var thumbnails: URL { documents.appendingPathComponent("Thumbnails", isDirectory: true) }
    static var exports: URL { documents.appendingPathComponent("Exports", isDirectory: true) }
    static var manifest: URL { documents.appendingPathComponent("photo-library.json") }

    static func prepare() throws {
        for directory in [originals, thumbnails, exports] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    static func original(_ record: PhotoRecord) -> URL { originals.appendingPathComponent(record.originalFilename) }
    static func thumbnail(_ record: PhotoRecord) -> URL { thumbnails.appendingPathComponent(record.thumbnailFilename) }

    static func newExportDirectory(prefix: String) throws -> URL {
        try prepare()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let name = "\(prefix)-\(formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-"))-\(UUID().uuidString.prefix(6))"
        let url = exports.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
