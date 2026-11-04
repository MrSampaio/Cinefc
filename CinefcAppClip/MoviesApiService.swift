//
//  MoviesApiService.swift
//  Cinefc
//
//  Created by Julio Sampaio on 31/10/26.
//

import Foundation
import Observation

@Observable
class MoviesApiService {
    var movie: MovieDetails?
    var isLoading = false
    var errorMessage: String?
    
    func fetchMovie(id: String) async throws -> MovieDetails {
        self.isLoading = true
        self.errorMessage = nil
        
        guard let url = URL(string: "https://movies-api-7009.onrender.com/api/cinema/movies/\(id)") else {
            self.isLoading = false
            self.errorMessage = "URL inválida."
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // valida retorno do servidor e se ele retornou 200 (ok)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.errorMessage = "Error when trying to fetch the movie"
                self.isLoading = false
                throw URLError(.badServerResponse)
            }
            
            // decodifica o JSON
            let decodedMovie = try JSONDecoder().decode(MovieDetails.self, from: data)
            
            // atribui na variável de estado
            self.movie = decodedMovie
            self.isLoading = false
            
            print(decodedMovie.title)
            print(decodedMovie.synopsis)
            
            // Retorna direto da chamada da API
            return decodedMovie
            
        } catch {
            self.errorMessage = "Connection error: \(error.localizedDescription)"
            self.isLoading = false
            
            // Repassa o erro para a View saber que falhou
            throw error
        }
    }
}
