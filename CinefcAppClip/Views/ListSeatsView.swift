//
//  ListSeatsView.swift
//  Cinefc
//

import SwiftUI

struct ListSeatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Recebe os dados da tela anterior
    let movie: MovieDetails
    let quantity: Int
    let quantityMeia: Int
    let total: Decimal
    
    // Estados para controlar os assentos e a sessão selecionada
    @State private var selectedShowtimeID: Int?
    @State private var seats: [Seat] = []
    @State private var isLoading = false
    
    @State private var apiService = MoviesApiService()
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Menu superior de horários
                showtimeMenu
                    .padding(.vertical, 16)
                
                Divider()
                
                if isLoading {
                    Spacer()
                    ProgressView("Carregando mapa de assentos...")
                        .padding(.top, 40)
                    Spacer()
                } else {
                    content
                }
                
                footer
            }
            .background(Color(.cineBackground))
        }
        .navigationTitle("Assentos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let firstShowtime = movie.showtimes.first {
                selectedShowtimeID = firstShowtime.id
                await fetchSeats(for: firstShowtime.id)
            }
        }
    }
    
    private func fetchSeats(for showtimeID: Int) async {
        isLoading = true
        seats = []
        
        do {
            let fetchedSeats = try await apiService.fetchSeats(showtimeID: showtimeID)
            self.seats = fetchedSeats
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
    
    // Scroll Horizontal com os horários
    private var showtimeMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Horários disponíveis")
                .font(.headline)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movie.showtimes) { showTime in
                        Button {
                            selectedShowtimeID = showTime.id
                            Task {
                                await fetchSeats(for: showTime.id)
                            }
                        } label: {
                            Text(showTime.startTime)
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedShowtimeID == showTime.id ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedShowtimeID == showTime.id ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            legend
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(seats) { seat in
                    SeatButton(seat: seat)
                }
            }
            .padding(.horizontal, 12)
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
//                    .fill(colorScheme == .dark ? Color(.systemGray2) : .gray)
                    .fill(.gray)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total a pagar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(total, format: .currency(code: "BRL"))
                        .font(.title3.bold())
                }
                
                Spacer()
                
                // Futura navegação para o simulador de pagamento
                Button("Ir para Pagamento") {
                    // Ação de ir para pagamento será adicionada depois
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}
private struct SeatButton: View {
    let seat: Seat
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            if seat.isAvailable {
                // Ação para selecionar cadeiras (será feita no próximo passo)
            }
        } label: {
            Text("\(seat.rowLetter)\(seat.seatNumber)")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(seat.isAvailable ? Color.accentColor : Color.gray)
        .foregroundStyle((colorScheme == .dark || seat.isAvailable) ? .white : .black)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
