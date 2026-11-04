//
//  OrderBackend.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 29/10/26.
//

import Foundation

protocol OrderBackend {
    func createOrder(show: Show, quantity: Int, email: String?, paymentToken: Data) async throws -> Order
}

// PoC: simula POST /orders. Em produção, envie o token ao PSP e crie o pedido no servidor.
struct MockOrderBackend: OrderBackend {
    func createOrder(show: Show, quantity: Int, email: String?, paymentToken: Data) async throws -> Order {
        try await Task.sleep(for: .seconds(1))
        print("Token: \(paymentToken.count) bytes | e-mail: \(email ?? "nil")")
        return Order(id: UUID().uuidString, ticketCode: "TKT-" + UUID().uuidString.prefix(8).uppercased(), showTitle: show.title, quantity: quantity, email: email ?? "nil")
    }
}
