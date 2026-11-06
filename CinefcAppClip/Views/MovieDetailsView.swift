//
//  MovieDetailsView.swift
//  TicketsClip
//

import SwiftUI
import PassKit

struct MovieDetailsView: View {
    let movieID: String
    
    @State var movie: MovieDetails?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    @State private var apiService = MoviesApiService()
    
    @State private var quantity: Int = 0
    @State private var quantityMeia: Int = 0
    let ticketPrice: Decimal = 25.0
    
    var totalPrice: Decimal {
        let precoInteira = ticketPrice * Decimal(quantity)
        let precoMeia = (ticketPrice / 2) * Decimal(quantityMeia)
        return precoMeia + precoInteira
    }
    
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
            await fetchMovie()
        }
    }
    
    private func fetchMovie() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMovie = try await apiService.fetchMovie(id: movieID)
            self.movie = fetchedMovie
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Não foi possível carregar os detalhes do filme."
            self.isLoading = false
        }
    }
    
    @ViewBuilder
    private func content(_ movie: MovieDetails) -> some View {
        NavigationStack {
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingressos:")
                            .font(.headline)
                        
                        Stepper("Inteira (R$ 25,00): \(quantity)", value: $quantity, in: 0...6)
                        Stepper("Meia (R$ 12,50): \(quantityMeia)", value: $quantityMeia, in: 0...6)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(totalPrice, format: .currency(code: "BRL")).font(.title2.bold())
                    }
                    
                    // Botão para ir para a tela de assentos
                    NavigationLink(destination: ListSeatsView(movie: movie, quantity: quantity, quantityMeia: quantityMeia, total: totalPrice)) {
                        Text("Escolher assentos")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background((quantity + quantityMeia > 0) ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(quantity + quantityMeia == 0)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
    }
}
