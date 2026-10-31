//
//  MoviesApiService.swift
//  Cinefc
//
//  Created by Julio Sampaio on 31/10/26.
//

import Foundation

class MoviesApiService {
    var movies: MovieDetails?
    var isLoading = false
    var errorMessage: String?
    
    func fetchMovie(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        #warning("depois muda a URL para o servidor deployado")
        guard let url = URL(string: "http://localhost:8080/api/cinema/movies/\(id)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // valida retorno do servidor e se ele retornou 200 (ok)
            guard let respose = response as? HTTPURLResponse, respose.statusCode == 200 else {
                self.errorMessage = "Error when trying to fetch the movie"
                self.isLoading = false
                return
            }
            
            // decodifica o JSON e atribui na variável de movie
            let decodedMovies = try JSONDecoder().decode(MovieDetails.self, from: data)
            self.movies = decodedMovies
            self.isLoading = false
            
        } catch{
            self.errorMessage = "Connection error: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}
