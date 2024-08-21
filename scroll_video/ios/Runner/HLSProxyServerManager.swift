import Foundation
import HLSCachingReverseProxyServer
import GCDWebServer
import PINCache

class HLSProxyServerManager {
    static let shared = HLSProxyServerManager()
    
    private var proxyServer: HLSCachingReverseProxyServer?
    
    private init() {
        setupProxyServer()
    }
    
    private func setupProxyServer() {
        let webServer = GCDWebServer()
        let urlSession = URLSession(configuration: .default)
        let cache = PINCache.shared

        proxyServer = HLSCachingReverseProxyServer(webServer: webServer, urlSession: urlSession, cache: cache)
        do {
            try proxyServer?.start(port: 8080)
            print("Proxy server started on port 8080")
        } catch {
            print("Failed to start proxy server on port 8080: \(error)")
            proxyServer?.stop()
        }
    }

    func getProxyUrl(for originalUrl: String) -> String? {
        guard let videoURL = URL(string: originalUrl) else {
            print("Invalid original URL")
            return nil
        }

        if let cachedUrl = proxyServer?.reverseProxyURL(from: videoURL) {
            print("Serving video from proxy URL: \(cachedUrl)")
            return cachedUrl.absoluteString
        } else {
            print("Failed to generate proxy URL")
            return nil
        }
    }

    deinit {
        proxyServer?.stop()
    }
}
