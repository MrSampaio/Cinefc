//
//  CinemaModels.swift
//  Cinefc
//
//  Created by Julio Sampaio on 31/10/26.
//

import Foundation

struct MovieDetails: Codable, Identifiable {
    let id: Int
    let title: String
    let synopsis: String
    let coverUrl: String
    let showtimes: [Showtime]
}

struct Showtime: Codable, Identifiable {
    let id: Int
    let startTime: String
    let seats: [Seat]?
}

struct Seat: Codable, Identifiable, Hashable{
    let id: Int
    let rowLetter: String
    let seatNumber: Int
    let isAvailable: Bool
}




