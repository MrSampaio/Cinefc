//
//  PurchaseConfirmationView.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 29/10/26.
//

import SwiftUI
import PassKit
import StoreKit

struct PurchaseConfirmationView: View {
    let order: Order
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            
            Text("Pagamento aprovado")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("\(order.quantity)x \(order.showTitle)")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Código do pedido")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(order.ticketCode)
                    .font(.title3.monospaced().bold())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Color.secondary.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 16)
            )
            
            if let email = order.email {
                Text("Confirmação enviada para \(email)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Esta é uma simulação de pagamento para a PoC.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: onDone) {
                Text("Finalizar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
