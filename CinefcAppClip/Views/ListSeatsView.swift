//
//  ListSeatsView.swift
//  Cinefc
//

import SwiftUI

struct ListSeatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let showtimeID: Int
    @State var seats: [Seat] = []
    @State var movieName: String = ""
    @State var showtime: String
    @State var isLoading = true
    
    @State private var apiService = MoviesApiService()
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
            
        ScrollView{
            VStack(spacing: 0) {
//                header
                
                if isLoading {
                    Spacer()
                    ProgressView("Carregando assentos...")
                    Spacer()
                } else {
                    content
                }
                
                footer
            }
//            .padding(.top, 24)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .top)
            .task {
                await fetchSeats()
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("\(movieName) • \(showtime)")
        .navigationBarTitleDisplayMode(.large)
//        .documentLaunchTitle("Filme")
//        .navigationTitle("Filme")
        
    }
    
    private func fetchSeats() async {
        isLoading = true
        
        do {
            let fetchedSeats = try await apiService.fetchSeats(showtimeID: showtimeID)
            self.seats = fetchedSeats
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
//    
//    private var header: some View {
//        ZStack(alignment: .top) {
//            Color(.systemGray4)
////            
////            LinearGradient(
////                colors: [.clear, .black.opacity(0.7)],
////                startPoint: .center,
////                endPoint: .bottom
////            )
//            
////            VStack(alignment: .leading, spacing: 4) {
////                Text("Filme")
////                    .font(.title.bold())
////                Text("classificacao · duracao · Legendado/dublado")
////                    .font(.caption)
////            }
////            .foregroundStyle(.white)
////            .padding(20)
//        }
//        .frame(height: 200)
//        .clipped()
//    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cadeiras disponíveis")
                .font(.headline)
            
            legend
                .frame(maxWidth: .infinity)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(seats) { seat in
                        SeatButton(seat: seat)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(24)
    }
    
    private var legend: some View {
        HStack(spacing: 16) {
            Label {
                Text("Disponível")
            } icon: {
                Circle().fill(.accent).frame(width: 10, height: 10)
            }
            Label {
                Text("Ocupado")
            } icon: {
                Circle()
                    .fill(colorScheme == .dark ? Color(.systemGray2) : .seatOccupied)
                    .frame(width: 10, height: 10)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.red)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image("AppIcon")
//                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distribuído por")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("CineFC")
                            .font(.subheadline.weight(.semibold))
                        Text("4+")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(.secondary, lineWidth: 0.5)
                            )
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Abrir") {
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

private struct SeatButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let seat: Seat
    
    var body: some View {
        Button {
        } label: {
            Text("\(seat.rowLetter)\(seat.seatNumber)")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(seat.isAvailable ? .accent : .seatOccupied)
        .disabled(!seat.isAvailable)
        .foregroundStyle(
            seat.isAvailable ? .white : colorScheme == .dark ? .white : .black
        )
        .background(.ultraThinMaterial, in: Capsule())
    }
}
