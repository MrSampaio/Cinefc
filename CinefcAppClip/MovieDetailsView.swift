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
    
    @State private var quantity: Int = 0
    @State private var quantityMeia: Int = 0
    let ticketPrice: Decimal = 25.0
    
    @State private var selectedShowtime: Showtime?
    
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
//        .task(id: movieID) {
//            await moviesViewModel.getMovieFromApi(id: movieID)
//        }
        .task(id: movieID) {
                    // Se estiver rodando no Preview do Xcode, pula a API e bota um mock instantâneo
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        self.movie = MovieDetails(
                            id: Int(movieID) ?? 1,
                            title: "Filme de Teste",
                            synopsis: "Sinopse exibida apenas no preview para testar o layout.",
                            coverUrl: "",
                            showtimes: [
                                Showtime(id: 1, startTime: "14:30"),
                                Showtime(id: 2, startTime: "18:00")
                            ]
                        )
                        self.isLoading = false
                        return
                    }
                    
                    // Seu fluxo normal de API para quando rodar no App real
                    await moviesViewModel.getMovieFromApi(id: movieID)
                    // Lembre de atualizar isLoading = false dentro do seu MoviesViewModel quando terminar
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
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Horários disponíveis").font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(movie.showtimes) { showTime in
                                SessaoCard(
                                    showtime: showTime,
                                    isSelected: selectedShowtime?.id == showTime.id
                                ) {
                                    selectedShowtime = showTime
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingressos:")
                    
                    Stepper("Inteira (R$ 25,00): \(quantity)", value: $quantity, in: 0...6)
                    Stepper("Meia (R$ 12,50): \(quantityMeia)", value: $quantityMeia, in: 0...6)
                }
                
                Divider()
                
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    let precoInteira = ticketPrice * Decimal(quantity)
                    let precoMeia = (ticketPrice / 2) * Decimal(quantityMeia)
                    let total = precoMeia + precoInteira
                    
                    Text(total, format: .currency(code: "BRL")).font(.title2.bold())
                }
                
                
            }
            .padding()
            
            VStack (alignment: .center){
                Button("Continuar") {
                    
                }
                .foregroundStyle(.white)
                .padding()
                .background(Capsule())
            }
        }
    }
}

struct SessaoCard: View {
    let showtime: Showtime
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(showtime.startTime)
                    .font(.subheadline)
                    .bold()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            // Muda a cor de fundo dependendo se está selecionado ou não
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

// MARK: - Previews com Dados Mockados

#Preview {
    MovieDetailsView(movieID: "1")
}
