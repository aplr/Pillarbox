//
//  Cache.swift
//  Pillarbox
//
//  Created by Andreas Pfurtscheller on 29.04.21.
//

import Foundation
import PINCache

@usableFromInline
class Cache {
    
    private let cache: PINCache
    
    private var cacheEncoder: JSONEncoder {
        JSONEncoder()
    }
    
    private var cacheDecoder: JSONDecoder {
        JSONDecoder()
    }
    
    @usableFromInline
    init(name: String, url: URL) {
        self.cache = PINCache(name: name, rootPath: url.path)
    }
    
    @usableFromInline
    func get<Element: Decodable>(forKey key: String) -> Element? {
        guard let data = self.cache.object(forKey: key) as? Data else { return nil }
        
        return try? cacheDecoder.decode(Element.self, from: data)
    }
    
    @usableFromInline
    func pull<Element: Decodable>(forKey key: String) -> Element? {
        defer { self.remove(forKey: key) }
        return self.get(forKey: key)
    }
    
    @usableFromInline
    func set<Element: Encodable>(_ element: Element, forKey key: String) {
        guard let data = try? cacheEncoder.encode(element) else { return }
        
        return self.cache.setObject(data, forKey: key)
    }
    
    @usableFromInline
    func contains(forKey key: String) -> Bool {
        self.cache.containsObject(forKey: key)
    }
    
    @usableFromInline
    func remove(forKey key: String) {
        self.cache.removeObject(forKey: key)
    }
    
    @usableFromInline
    func removeAll() {
        self.cache.removeAllObjects()
    }
    
    @usableFromInline
    subscript<Element: Codable>(_ key: String) -> Element? {
        get {
            self.get(forKey: key)
        } set {
            self.set(newValue, forKey: key)
        }
    }
}
