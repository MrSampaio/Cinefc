//
//  ListSeatsView.swift
//  Cinefc
//
//  Created by Isabella Avelina on 04/11/26.
//

import SwiftUI

struct ListSeatsView: View {
    @Environment(\.dismiss) private var dismiss

    private let seats: [SeatItem] = [
        SeatItem(label: "A1", isAvailable: true),  SeatItem(label: "A2", isAvailable: true),
        SeatItem(label: "A3", isAvailable: false), SeatItem(label: "A4", isAvailable: true),
        SeatItem(label: "B1", isAvailable: true),  SeatItem(label: "B2", isAvailable: false),
        SeatItem(label: "B3", isAvailable: false), SeatItem(label: "B4", isAvailable: true),
        SeatItem(label: "C1", isAvailable: true),  SeatItem(label: "C2", isAvailable: true),
        SeatItem(label: "C3", isAvailable: true),  SeatItem(label: "C4", isAvailable: false),
        SeatItem(label: "D1", isAvailable: false), SeatItem(label: "D2", isAvailable: true),
        SeatItem(label: "D3", isAvailable: true),  SeatItem(label: "D4", isAvailable: true)
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            Color(.systemGray4)

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Filme")
                    .font(.title.bold())
                Text("classificacao · duracao · Legendado/dublado")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(height: 410)
        .clipped()
        .overlay(alignment: .top) {
        }
    }

    private func circleButton(systemName: String) -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
    }


    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cadeiras disponíveis")
                .font(.headline)

            legend
                .frame(maxWidth: .infinity)

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
                Circle().fill(.green).frame(width: 10, height: 10)
            }
            Label {
                Text("Ocupado")
            } icon: {
                Circle().fill(.gray).frame(width: 10, height: 10)
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
                        Image(systemName: "film")
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Distribuído por")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("CineLume")
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
    let label: String
    // true = disponível (verde), false = ocupado (cinza)
    @State private var isAvailable: Bool

    init(seat: SeatItem) {
        self.label = seat.label
        _isAvailable = State(initialValue: seat.isAvailable)
    }

    var body: some View {
        Button {
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(isAvailable ? .green : .gray)
        .foregroundStyle(.white)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
    }
}

private struct SeatItem: Identifiable {
    let id = UUID()
    let label: String
    let isAvailable: Bool
}

#Preview {
    ListSeatsView()
}
