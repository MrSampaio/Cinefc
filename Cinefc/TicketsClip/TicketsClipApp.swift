//
//  TicketsClipApp.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 28/10/26.
//

import SwiftUI

@main
struct TicketsClipApp: App {
    @State private var showID: String?
    @State private var timedOut = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let showID {
                    ShowDetailView(showID: showID)
                } else if timedOut {
                    ContentUnavailableView(
                        "Escaneie o QR Code do evento",
                        systemImage: "qrcode.viewfinder",
                        description: Text("Não encontramos um evento neste link.")
                    )
                } else {
                    ProgressView("Abrindo evento…")
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else { return }
                print("URL Recebida: ", url.absoluteString)
                showID = DeepLink.showID(from: url)
            }
            .task {
                try? await Task.sleep(for: .seconds(3))
                if showID == nil { timedOut = true }
            }
        }
    }
}
