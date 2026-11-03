//
//  PurchaseConfirmationView.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 29/10/26.
//

import SwiftUI
import PassKit
import StoreKit

enum WalletPass {
    /// Carrega o Ticket.pkpass embutido no bundle do clip (PoC).
    static func load() -> PKPass? {
        guard let url = Bundle.main.url(forResource: "Ticket", withExtension: "pkpass"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? PKPass(data: data)
    }
}

struct AddPassSheet: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> UIViewController {
        let vc: PKAddPassesViewController? = PKAddPassesViewController(pass: pass)
        return vc ?? UIViewController()
    }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}
}

struct PurchaseConfirmationView: View {
    let order: Order
    let onDone: () -> Void
    @State private var showWallet = false
    @State private var showOverlay = false
    private let pass = WalletPass.load()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Compra confirmada!").font(.title.bold())
            Text("\(order.quantity)x \(order.showTitle)")
            Text("Código: \(order.ticketCode)")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
            if let email = order.email {
                Text("Ingresso enviado para \(email)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if pass != nil, PKAddPassesViewController.canAddPasses() {
                Button {
                    showWallet = true
                } label: {
                    Label("Adicionar à Wallet", systemImage: "wallet.pass")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("Continuar comprando", action: onDone)
                .buttonStyle(.bordered)
        }
        .padding()
        .sheet(isPresented: $showWallet) {
            if let pass { AddPassSheet(pass: pass) }
        }
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
        .onAppear{ showOverlay = true }
    }
}
