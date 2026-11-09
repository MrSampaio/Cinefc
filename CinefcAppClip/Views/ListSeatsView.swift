//
//  ListSeatsView.swift
//  Cinefc
//

import SwiftUI
import PassKit

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
    
    // verifica onde tá rodando
    private var isRunningOnSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
    
    private func simulatePayment() {
        
        guard totalIngressos > 0 else {
            paymentError = "Selecione pelo menos um ingresso."
            return
        }
        
        guard selectedSeats.count == totalIngressos else {
            paymentError = "Selecione todos os assentos."
            return
        }
        
        let unitPrice = total / Decimal(totalIngressos)
        
        let paymentShow = Show(
            id: String(movie.id),
            title: movie.title,
            venue: "Cinema CineFC",
            date: .now,
            unitPrice: unitPrice
        )
        
        isPaymentInProgress = true
        paymentError = nil
        
        Task { @MainActor in
            do {
                let order = try await applePayService.simulatePayment(
                    show: paymentShow,
                    quantity: totalIngressos
                )
                
                isPaymentInProgress = false
                completedOrder = order
            } catch {
                print("erro na simulação:", error)
                
                isPaymentInProgress = false
                paymentError = "não foi possível concluir a simulação."
            }
        }
    }
    
    
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
    
    private var legend: some View {
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
                
                VStack(spacing: 10) {
                    PayWithApplePayButton(
                        .buy,
                        action: startPayment
                    )
                    .payWithApplePayButtonStyle(
                        colorScheme == .dark ? .white : .black
                    )
                    .frame(width: 190, height: 50)
                    .disabled(
                        selectedSeats.count != totalIngressos ||
                        isPaymentInProgress
                    )
                    .opacity(
                        selectedSeats.count == totalIngressos &&
                        !isPaymentInProgress
                        ? 1
                        : 0.5
                    )
                    
#if targetEnvironment(simulator)
                    Button(action: simulatePayment) {
                        if isPaymentInProgress {
                            ProgressView()
                        } else {
                            Label(
                                "Concluir simulação",
                                systemImage: "checkmark.circle"
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        selectedSeats.count != totalIngressos ||
                        isPaymentInProgress
                    )
                    
                    Text("Modo de apresentação: nenhuma cobrança será realizada.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
#endif
                }
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
            .tint(isSelected ? .orange : (seat.isAvailable ? Color.accentColor : .gray))
            .disabled(!seat.isAvailable)
            .foregroundStyle((colorScheme == .dark || seat.isAvailable) ? .white : .black)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    // função que começa o processo de pagamento
    private func startPayment() {
        
        guard totalIngressos > 0 else {
            paymentError = "selecione pelo menos um ingresso."
            return
        }
        
        guard selectedSeats.count == totalIngressos else {
            paymentError = "selecione todos os assentos."
            return
        }
        
        let unitPrice = total / Decimal(totalIngressos)
        
        let paymentShow = Show(
            id: String(movie.id),
            title: movie.title,
            venue: "Cinema CineFC",
            date: .now,
            unitPrice: unitPrice
        )
        
        isPaymentInProgress = true
        paymentError = nil
        
        // task para validar o dtatus do apple pay service e exibir os erros
        Task { @MainActor in
            do {
                let order = try await applePayService.pay(
                    show: paymentShow,
                    quantity: totalIngressos
                )
                
                isPaymentInProgress = false
                completedOrder = order
            } catch let error as ApplePayService.PayError {
                isPaymentInProgress = false
                
                print("erro do Apple Pay:", error.localizedDescription)
                
                switch error {
                    case .cancelled:
                        paymentError = "Pagamento cancelado."
                        
                    case .unavailable:
                        paymentError =
                        "Apple Pay indisponível neste dispositivo."
                        
                    case .presentationFailed:
                        paymentError =
                        "Não foi possível abrir o Apple Pay."
                        
                    case .paymentFailed:
                        paymentError =
                        "Não foi possível concluir a simulação."
                }
            } catch {
                isPaymentInProgress = false
                
                print("Erro:", error)
                
                paymentError = error.localizedDescription
            }
        }
    }
}
