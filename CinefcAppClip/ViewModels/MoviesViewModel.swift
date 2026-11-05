//
//  MoviesViewModel.swift
//  CinefcAppClip
//
//  Created by Julio Sampaio on 04/11/26.
//

import Foundation
import SwiftUI
import Observation

@Observable
final class MoviesViewModel {
    
    private let apiService = MoviesApiService()
    var state: State = .loading
    
    enum State { case loading, loaded(MovieDetails), failed(String) }
    
    func getMovieFromApi(id: String) async{
        self.state = .loading
        do {
            let fetchedMovie = try await apiService.fetchMovie(id: id)
            self.state = .loaded(fetchedMovie)
        } catch {
            self.state = .failed("Erro ao carregar o filme: \(error.localizedDescription)")
        }
        
    }
}
