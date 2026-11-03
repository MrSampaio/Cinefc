//
//  Show.swift
//  TicketsPoC
//
//  Created by Igor Carrasco on 28/10/26.
//

import Foundation

struct Show: Identifiable, Equatable {
    let id: String
    let title: String
    let venue: String
    let date: Date
    let unitPrice: Decimal   // Decimal para dinheiro, nunca Double
}

enum ShowRepository {
    // PoC: mock. Trocar por uma chamada à API ou mocks de filmes.
    static func fetch(id: String) async throws -> Show {
        try await Task.sleep(for: .milliseconds(400))
        guard id == "banda-rock" else { throw URLError(.fileDoesNotExist) }
        return Show(id: id,
                    title: "Banda Rock Live",
                    venue: "Allianz Parque, São Paulo",
                    date: .now.addingTimeInterval(60 * 60 * 24 * 30),
                    unitPrice: 180)
    }
}
