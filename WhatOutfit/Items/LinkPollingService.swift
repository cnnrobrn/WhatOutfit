//
//  LinkPollingService.swift
//  WhatOutfit
//

import Foundation
import Combine

class LinkPollingService: ObservableObject {
    static let shared = LinkPollingService()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPolling = false
    
    func startPolling(for items: [item], updateHandler: @escaping ([item]) -> Void) {
        guard !isPolling else { return }
        isPolling = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let group = DispatchGroup()
            var updatedItems = items
            var hasNewLinks = false
            
            for (index, item) in items.enumerated() {
                group.enter()
                
                self.fetchLinks(for: item) { newLinks in
                    if let newLinks = newLinks {
                        let oldCount = item.links?.count ?? 0
                        if newLinks.count > oldCount {
                            hasNewLinks = true
                            updatedItems[index].links = newLinks
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if hasNewLinks {
                    updateHandler(updatedItems)
                } else if !items.contains(where: { $0.links?.isEmpty ?? true }) {
                    // All items have links, stop polling
                    self.stopPolling()
                }
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }
    
    private func fetchLinks(for item: item, completion: @escaping ([ProductLink]?) -> Void) {
        guard let url = URL(string: "https://access.wha7.com/api/links?item_id=\(item.itemId)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [ProductLink].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { links in
                    completion(links)
                }
            )
            .store(in: &cancellables)
    }
}