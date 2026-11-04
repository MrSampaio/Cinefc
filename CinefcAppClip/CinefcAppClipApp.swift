//
//  CinefcAppClipApp.swift
//  CinefcAppClip
//
//  Created by Julio Sampaio on 03/11/26.
//

import SwiftUI

@main
struct CinefcAppClipApp: App {
    @State private var movieID: String?
    @State private var timedOut = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let movieID {
                    MovieDetailsView(movieID: movieID)
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
                movieID = DeepLink.movieID(from: url)
            }
            .task {
                try? await Task.sleep(for: .seconds(3))
                if movieID == nil { timedOut = true }
            }
        }
    }
}
