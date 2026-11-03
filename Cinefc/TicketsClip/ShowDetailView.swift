//
//  ShowDetailView.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 28/10/26.
//

import SwiftUI
import PassKit

@MainActor
@Observable
final class ShowDetailViewModel {
    enum State { case loading, loaded(Show), failed(String) }

    var state: State = .loading
    var quantity = 1
    var paymentMessage: String?
    var order: Order?

    private let payment = ApplePayService()

    func load(id: String) async {
        do { state = .loaded(try await ShowRepository.fetch(id: id)) }
        catch { state = .failed("Evento não encontrado.") }
    }

    func total(for show: Show) -> Decimal {
        show.unitPrice * Decimal(quantity)
    }

    func pay(show: Show) async {
        do {
            order = try await payment.pay(show: show, quantity: quantity)
        } catch ApplePayService.PayError.cancelled {
            // usuário cancelou: sem alerta
        } catch ApplePayService.PayError.unavailable {
            paymentMessage = "Apple Pay indisponível. Adicione um cartão na Carteira."
        } catch {
            paymentMessage = "Falha no pagamento. Tente novamente."
        }
    }
    
    func reset() {
        order = nil
        quantity = 1
    }
}

struct ShowDetailView: View {
    let showID: String
    @State private var vm = ShowDetailViewModel()

    var body: some View {
        Group {
            if let order = vm.order {
                PurchaseConfirmationView(order: order) {
                    vm.reset()
                }
            } else {
                switch vm.state {
                case .loading:
                    ProgressView()
                case .failed(let message):
                    ContentUnavailableView(message, systemImage: "ticket")
                case .loaded(let show):
                    content(show)
                }
            }
        }
        .task(id: showID) { await vm.load(id: showID) }
        .alert("Pagamento",
               isPresented: Binding(
                   get: { vm.paymentMessage != nil },
                   set: { if !$0 { vm.paymentMessage = nil } })
        ) {
            Button("OK") {}
        } message: {
            Text(vm.paymentMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(_ show: Show) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(show.title).font(.largeTitle.bold())
            Label(show.venue, systemImage: "mappin.and.ellipse")
            Label(show.date.formatted(date: .long, time: .shortened),
                  systemImage: "calendar")

            Stepper("Ingressos: \(vm.quantity)", value: $vm.quantity, in: 1...6)

            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(vm.total(for: show), format: .currency(code: "BRL"))
                    .font(.title2.bold())
            }

            Spacer()

            PayWithApplePayButton(.buy) {
                Task { await vm.pay(show: show) }
            }
            .frame(height: 52)
        }
        .padding()
    }
}
