import Foundation
import GCDWebServer
import PINCache
import HLSCachingReverseProxyServer

@objc class VideoProxyManager: NSObject {
    private var webServer: GCDWebServer!
    private var cache: PINCache!
    private var server: HLSCachingReverseProxyServer!

    override init() {
        super.init()
        setupProxyServer()
    }

    private func setupProxyServer() {
        // Initialize GCDWebServer
        self.webServer = GCDWebServer()

        // Initialize PINCache with a specific name
        self.cache = PINCache(name: "reverse")

        // Set cache size and age limits
        self.cache.diskCache.byteLimit = 100 * 1024 * 1024 // 100 MB size limit
        self.cache.diskCache.ageLimit = 60 * 60 * 24 // 1 day age limit

        // Initialize the HLSCachingReverseProxyServer with the cache and web server
        self.server = HLSCachingReverseProxyServer(webServer: self.webServer, urlSession: .shared, cache: self.cache)
        
        do {
            try self.server.start(port: 1234)
            print("Reverse Proxy Server started on port 1234")
        } catch {
            print("Error starting reverse proxy server: \(error.localizedDescription)")
        }
    }

    func getProxyURL(originalURL: String) -> String? {
        guard let originURL = URL(string: originalURL) else {
            print("Invalid URL")
            return nil
        }

        // Check if only one segment is cached, if not, cache the current segment
        if !handleCachingForSegment(segmentURL: originURL) {
            print("Failed to cache segment")
            return nil
        }
        
        let proxyURL = self.server.reverseProxyURL(from: originURL)?.absoluteString
        if let proxyURL = proxyURL {
            print("[VideoProxyManager] Proxy URL: \(proxyURL)")
        } else {
            print("[VideoProxyManager] Failed to generate proxy URL")
        }

        return proxyURL
    }

    private func handleCachingForSegment(segmentURL: URL) -> Bool {
        // Remove any previously cached segments
        self.cache.diskCache.removeAllObjects()
        print("[VideoProxyManager] Cache cleared")

        // Generate a SHA256 hash of the URL for the cache key
        let cacheKey = segmentURL.absoluteString.sha256()
        print("[VideoProxyManager] Cache Key: \(cacheKey)")

        // Create a URL session data task to fetch and cache the segment
        let task = URLSession.shared.dataTask(with: segmentURL) { [weak self] data, response, error in
            if let error = error {
                print("[VideoProxyManager] Error fetching segment: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("[VideoProxyManager] No data received")
                return
            }
            
            // Cache the segment data
            )
            self?.cache.diskCache.setObject(PINCacheObject(data: data), forKey: cacheKey)
            print("[VideoProxyManager] Segment cached for URL: \(segmentURL.absoluteString)")
        }
        task.resume()
        
        return true
    }
}


//import Foundation
//import GCDWebServer
//import PINCache
//import HLSCachingReverseProxyServer
//
//@objc class VideoProxyManager: NSObject {
//    private var webServer: GCDWebServer!
//    private var cache: PINCache!
//    private var server: HLSCachingReverseProxyServer!
//
//    override init() {
//        super.init()
//        setupProxyServer()
//    }
//
//    private func setupProxyServer() {
//        // Initialize GCDWebServer
//        self.webServer = GCDWebServer()
//
//        // Initialize PINCache with a specific name
//        self.cache = PINCache(name: "reverse")
//
//        // Set cache size and age limits
//        self.cache.diskCache.byteLimit = 100 * 1024 * 1024 // 100 MB size limit
//        self.cache.diskCache.ageLimit = 60 * 60 * 24 // 1 day age limit
//
//        // Initialize the HLSCachingReverseProxyServer with the cache and web server
//        self.server = HLSCachingReverseProxyServer(webServer: self.webServer, urlSession: .shared, cache: self.cache)
//        
//        do {
//            try self.server.start(port: 1234)
//            print("Reverse Proxy Server started on port 1234")
//        } catch {
//            print("Error starting reverse proxy server: \(error.localizedDescription)")
//        }
//    }
//
//    func getProxyURL(originalURL: String) -> String? {
//        guard let originURL = URL(string: originalURL) else {
//            print("Invalid URL")
//            return nil
//        }
//
//        // Check if only one segment is cached, if not, cache the current segment
//        if !handleCachingForSegment(segmentURL: originURL) {
//            print("Failed to cache segment")
//            return nil
//        }
//        
//        let proxyURL = self.server.reverseProxyURL(from: originURL)?.absoluteString
//        if let proxyURL = proxyURL {
//            print("[VideoProxyManager] Proxy URL: \(proxyURL)")
//        } else {
//            print("[VideoProxyManager] Failed to generate proxy URL")
//        }
//
//        return proxyURL
//    }
//
//    private func handleCachingForSegment(segmentURL: URL) -> Bool {
//        // Remove any previously cached segments
//        self.cache.diskCache.removeAllObjects()
//
//        // Generate a SHA256 hash of the URL for the cache key
//        let cacheKey = segmentURL.absoluteString.sha256()
//
//        // Save the current segment in cache using the shorter hash key
//        // For simplicity, assuming you have a method to fetch and cache the segment data
//        if let data = fetchData(from: segmentURL) {
//            self.cache.setObject(data, forKey: cacheKey)
//            return true
//        }
//
//        return false
//    }
//
//    private func fetchData(from url: URL) -> Data? {
//        // Example function to fetch data from URL
//        // Replace with actual implementation
//        var data: Data?
//        let semaphore = DispatchSemaphore(value: 0)
//        
//        let task = URLSession.shared.dataTask(with: url) { fetchedData, _, _ in
//            data = fetchedData
//            semaphore.signal()
//        }
//        task.resume()
//        _ = semaphore.wait(timeout: .distantFuture)
//        
//        return data
//    }
//}
