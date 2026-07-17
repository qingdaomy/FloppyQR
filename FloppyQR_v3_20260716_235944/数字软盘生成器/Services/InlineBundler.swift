import Foundation

struct InlineBundler {

    static func bundle(directory: URL) throws -> String {
        let indexURL = directory.appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            throw BundlerError("未找到 index.html")
        }
        var html = try String(contentsOf: indexURL, encoding: .utf8)

        html = inlineByTag(html, tag: "link", attr: "href", baseURL: directory) { url, ext in
            guard ext == "css", let css = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return "<style>\(css)</style>"
        }

        html = inlineByTag(html, tag: "script", attr: "src", baseURL: directory) { url, ext in
            guard ext == "js", let js = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return "<script>\(js)</script>"
        }

        html = inlineImages(html, baseURL: directory)

        return html
    }

    private static func inlineByTag(_ html: String, tag: String, attr: String, baseURL: URL, handler: (URL, String) -> String?) -> String {
        var result = html
        let open = "<\(tag) "
        let attrMark = " \(attr)=\""
        var i = result.startIndex

        while i < result.endIndex, let s = result[i...].range(of: open) {
            let rest = result[s.upperBound...]
            guard let c = rest.firstIndex(of: Character(">")),
                  let a = rest.range(of: attrMark),
                  a.lowerBound < c else { i = s.upperBound; continue }

            let vStart = a.upperBound
            guard let vEnd = rest[vStart...].firstIndex(of: Character("\"")),
                  vEnd < c else { i = s.upperBound; continue }

            let val = String(rest[vStart..<vEnd])
            let url = resolveURL(val, base: baseURL)
            let ext = url.pathExtension.lowercased()

            let tagRange = s.lowerBound..<rest.index(after: c)
            if let repl = handler(url, ext) {
                result.replaceSubrange(tagRange, with: repl)
                i = tagRange.lowerBound
            } else {
                i = rest.index(after: c)
            }
        }
        return result
    }

    private static func resolveURL(_ src: String, base: URL) -> URL {
        if src.hasPrefix("/") { return base.appendingPathComponent(String(src.dropFirst())) }
        return URL(string: src, relativeTo: base) ?? base.appendingPathComponent(src)
    }

    private static func inlineImages(_ html: String, baseURL: URL) -> String {
        var result = html
        let mark = " src=\""
        var i = result.startIndex

        while i < result.endIndex, let s = result[i...].range(of: mark) {
            let rest = result[s.upperBound...]
            guard let e = rest.firstIndex(of: Character("\"")) else { break }
            let src = String(rest[..<e])
            let url = resolveURL(src, base: baseURL)
            let ext = url.pathExtension.lowercased()
            if let data = try? Data(contentsOf: url) {
                let mime = ext == "png" ? "image/png" : ext == "jpg" || ext == "jpeg" ? "image/jpeg" : ext == "gif" ? "image/gif" : ext == "svg" ? "image/svg+xml" : ext == "webp" ? "image/webp" : ext == "ico" ? "image/x-icon" : "image/\(ext)"
                let full = "\(mark)\(src)\""
                if let r = result.range(of: full, range: i..<result.endIndex) {
                    let repl = " src=\"data:\(mime);base64,\(data.base64EncodedString())\""
                    result.replaceSubrange(r, with: repl)
                }
            }
            i = result.index(s.lowerBound, offsetBy: 1, limitedBy: result.endIndex) ?? result.endIndex
        }
        return result
    }
}

struct BundlerError: Error, LocalizedError {
    var errorDescription: String?
    init(_ msg: String) { errorDescription = msg }
}
