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
    
    private let rows = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Horários disponíveis").font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            
                            LazyHGrid(rows: rows, spacing: 12) {
                                ForEach(movie.showtimes) { showTime in
                                    NavigationLink(
                                        destination: ListSeatsView(
                                            showtimeID: showTime.id,
                                            movieName: movie.title,
                                            showtime: showTime.startTime
                                        )
                                    ) {
                                        SessaoCard(showtime: showTime)
                                    }
                                }
                            }
                            .frame(height: 110)
                            
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingressos:")
                        
                        Stepper("Inteira (R$ 25,00): \(quantity)", value: $quantity, in: 0...6)
                        Stepper("Meia (R$ 12,50): \(quantityMeia)", value: $quantityMeia, in: 0...6)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .foregroundStyle(Color.accent)
                        
                        Spacer()
                        
                        let precoInteira = ticketPrice * Decimal(quantity)
                        let precoMeia = (ticketPrice / 2) * Decimal(quantityMeia)
                        let total = precoMeia + precoInteira
                        
                        Text(total, format: .currency(code: "BRL")).font(.title2.bold())
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct SessaoCard: View {
    let showtime: Showtime
    
    var body: some View {
        VStack {
            Text(showtime.startTime)
                .font(.subheadline)
                .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
