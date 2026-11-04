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
