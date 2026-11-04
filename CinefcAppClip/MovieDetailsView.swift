//
//  MovieDetailsView.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 28/10/26.
//

import SwiftUI
import PassKit

struct MovieDetailsView: View {
    let movieID: String
    
    // Estados locais da View para controlar o carregamento e os dados
    @State private var movie: MovieDetails? = nil
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    // Instanciamos o serviço diretamente
    @State private var apiService = MoviesApiService()
    
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
            await fetchMovie()
        }
    }
    
    // função auxiliar para manter o .task limpo
    private func fetchMovie() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Aqui fazemos a chamada e recebemos o filme diretamente da função!
            let fetchedMovie = try await apiService.fetchMovie(id: movieID)
            
            // Atualizamos o estado da View com o filme recebido
            self.movie = fetchedMovie
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Não foi possível carregar os detalhes do filme."
            self.isLoading = false
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
