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
    var seats: [Seat] = []
    
    var isLoading = false
    var errorMessage: String?
    
    func fetchMovie(id: String) async throws -> MovieDetails {
        self.isLoading = true
        self.errorMessage = nil
        
        print(id)
        
        // verifica a url formada com o parâmetro
        guard let url = URL(string: "https://movies-api-7009.onrender.com/api/cinema/movies/\(id)") else {
            self.isLoading = false
            self.errorMessage = "URL inválida."
            throw URLError(.badURL)
        }
        
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            config.timeoutIntervalForResource = 10.0
            let customSession = URLSession(configuration: config)
            
            let (data, response) = try await customSession.data(from: url)
            
            // verifica resposta do servidor
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.errorMessage = "Error when trying to fetch the movie"
                self.isLoading = false
                throw URLError(.badServerResponse)
            }
            
            // decodifica o json recebido pela API
            let decodedMovie = try JSONDecoder().decode(MovieDetails.self, from: data)
            
            self.movie = decodedMovie
            self.isLoading = false
            
            print(decodedMovie.title)
            print(decodedMovie.synopsis)
            
            return decodedMovie
            
        } catch {
            self.errorMessage = "Connection error: \(error.localizedDescription)"
            self.isLoading = false
            
            throw error
        }
    }
    
    func fetchSeats(showtimeID: Int) async throws -> [Seat] {
        self.isLoading = true
        self.errorMessage = nil
        
        guard let url = URL(string: "https://movies-api-7009.onrender.com/api/cinema/showtimes/\(showtimeID)/seats") else {
            self.isLoading = false
            self.errorMessage = "URL inválida."
            throw URLError(.badURL)
        }
        
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            config.timeoutIntervalForResource = 10.0
            let customSession = URLSession(configuration: config)
            
            let (data, response) = try await customSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Erro de servidor")
                self.errorMessage = "Error when trying to fetch seats"
                self.isLoading = false
                throw URLError(.badServerResponse)
            }
            
            let decodedSeats = try JSONDecoder().decode([Seat].self, from: data)
            self.seats = decodedSeats
            self.isLoading = false
            
            return decodedSeats
            
        } catch {
            print("Erro ao buscar assentos: \(error)")
            self.errorMessage = "Connection error: \(error.localizedDescription)"
            self.isLoading = false
            throw error
        }
    }
}
