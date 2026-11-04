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

struct MovieDetailsView: View {
//    let showID: String
//    @State private var vm = ShowDetailViewModel()
//
//    var body: some View {
//        Group {
//            if let order = vm.order {
//                PurchaseConfirmationView(order: order) {
//                    vm.reset()
//                }
//            } else {
//                switch vm.state {
//                case .loading:
//                    ProgressView()
//                case .failed(let message):
//                    ContentUnavailableView(message, systemImage: "ticket")
//                case .loaded(let show):
//                    content(show)
//                }
//            }
//        }
//        .task(id: showID) { await vm.load(id: showID) }
//        .alert("Pagamento",
//               isPresented: Binding(
//                   get: { vm.paymentMessage != nil },
//                   set: { if !$0 { vm.paymentMessage = nil } })
//        ) {
//            Button("OK") {}
//        } message: {
//            Text(vm.paymentMessage ?? "")
//        }
//    }
    
    let movieID: String
    
    @State private var movie: MovieDetails? = nil
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    @State private var moviesViewModel = MoviesViewModel()
    
    @State private var quantity: Int = 1
    let ticketPrice: Decimal = 25.0
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Buscando o filme...")
            } else if let error = errorMessage {
                ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
            } else if let movie = movie {
                content(movie)
            }
        }
        .task(id: movieID) {
            await moviesViewModel.getMovieFromApi(id: movieID)
        }
    }

    @ViewBuilder
    private func content(_ movie: MovieDetails) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: movie.coverUrl)) { image in
                    image.resizable().scaledToFit().cornerRadius(12)
                } placeholder: {
                    ProgressView().frame(height: 300)
                }
                
                Text(movie.title).font(.largeTitle.bold())
                Text(movie.synopsis).font(.body).foregroundColor(.secondary)
                
                Divider()
                
                Stepper("Ingressos: \(quantity)", value: $quantity, in: 1...6)
                
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    let total = ticketPrice * Decimal(quantity)
                    Text(total, format: .currency(code: "BRL")).font(.title2.bold())
                }
            }
            .padding()
        }
    }
}
