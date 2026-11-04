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
    func fetchMovie(id: String) async throws -> MovieDetails {
        guard let url = URL(string: "https://movies-api-7009.onrender.com/api/cinema/movies/\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(MovieDetails.self, from: data)
    }
}
