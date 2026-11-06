//
//  ListSeatsView.swift
//  Cinefc
//

import SwiftUI

struct ListSeatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let movie: MovieDetails
    let quantity: Int
    let quantityMeia: Int
    let total: Decimal
    
    var totalIngressos: Int { quantity + quantityMeia }
    
    @State private var selectedShowtimeID: Int?
    @State private var seats: [Seat] = []
    @State private var isLoading = false
    
    @State private var selectedSeats: Set<Int> = []
    
    @State private var applePayService = ApplePayService()
    @State private var isPaymentInProgress = false
    @State private var paymentError: String? = nil
    @State private var completedOrder: Order? = nil
    
    @State private var apiService = MoviesApiService()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                showtimeMenu.padding(.vertical, 16)
                Divider()
                
                if isLoading {
                    Spacer()
                    ProgressView("Carregando mapa de assentos...").padding(.top, 40)
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
        .fullScreenCover(item: $completedOrder) { order in
            PurchaseConfirmationView(order: order) {
                dismiss()
            }
        }
    }
    
    private func fetchSeats(for showtimeID: Int) async {
        isLoading = true
        seats = []
        selectedSeats.removeAll()
        
        do {
            let fetchedSeats = try await apiService.fetchSeats(showtimeID: showtimeID)
            self.seats = fetchedSeats
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
    
    private var showtimeMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Horários disponíveis").font(.headline).padding(.horizontal, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movie.showtimes) { showTime in
                        Button {
                            selectedShowtimeID = showTime.id
                            Task { await fetchSeats(for: showTime.id) }
                        } label: {
                            Text(showTime.startTime)
                                .font(.subheadline).bold()
                                .padding(.horizontal, 16).padding(.vertical, 12)
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
            legend.frame(maxWidth: .infinity).padding(.bottom, 10)
            
            // Aviso dinâmico de contagem de lugares
            HStack {
                Text("Selecione \(totalIngressos) assento(s)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(selectedSeats.count)/\(totalIngressos)")
                    .font(.subheadline.bold())
                    .foregroundColor(selectedSeats.count == totalIngressos ? .green : .blue)
            }
            .padding(.horizontal, 12)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(seats) { seat in
                    SeatButton(
                        seat: seat,
                        isSelected: selectedSeats.contains(seat.id),
                        action: {
                            toggleSeatSelection(seat: seat)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(24)
    }
    
    private func toggleSeatSelection(seat: Seat) {
        if selectedSeats.contains(seat.id) {
            selectedSeats.remove(seat.id)
        } else {
            if selectedSeats.count < totalIngressos {
                selectedSeats.insert(seat.id)
            }
        }
    }
    
    private var legend: some View { /* Sem alterações */
        HStack(spacing: 16) {
            Label { Text("Disponível") } icon: { Circle().fill(.accent).frame(width: 10, height: 10) }
            Label { Text("Ocupado") } icon: { Circle().fill(.gray).frame(width: 10, height: 10) }
            Label { Text("Selecionado") } icon: { Circle().fill(.orange).frame(width: 10, height: 10) }
        }
        .font(.caption).foregroundStyle(.secondary)
    }
    
    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            
            if let error = paymentError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total a pagar")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(total, format: .currency(code: "BRL")).font(.title3.bold())
                }
                
                Spacer()
                
                Button(action: startPayment) {
                    if isPaymentInProgress {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedSeats.count == totalIngressos ? "Pagar com Pay" : "Escolha cadeiras")
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(selectedSeats.count != totalIngressos || isPaymentInProgress)
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
        }
    }
    
    private struct SeatButton: View {
        let seat: Seat
        let isSelected: Bool
        let action: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            Button(action: action) {
                Text("\(seat.rowLetter)\(seat.seatNumber)")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            
            // As Cores: Laranja se selecionado, Azul se livre, Cinza se ocupado
            .tint(isSelected ? .orange : (seat.isAvailable ? Color.accentColor : .gray))
            .disabled(!seat.isAvailable)
            
            // Letra: Sempre branca se DarkMode/Disponível, ou Preta no modo claro
            .foregroundStyle((colorScheme == .dark || seat.isAvailable) ? .white : .black)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    private func startPayment() {
        let mockShow = Show(
            id: String(movie.id),
            title: movie.title,
            venue: "Cinema CineFC",
            date: .now,
            unitPrice: total / Decimal(totalIngressos)
        )
        
        isPaymentInProgress = true
        paymentError = nil
        
        Task {
            do {
                let order = try await applePayService.pay(show: mockShow, quantity: totalIngressos)
                self.completedOrder = order
            } catch {
                if let payError = error as? ApplePayService.PayError, payError == .cancelled {
                    self.paymentError = "Pagamento cancelado."
                } else {
                    self.paymentError = "Ocorreu um erro no pagamento."
                }
            }
            isPaymentInProgress = false
        }
    }
}
