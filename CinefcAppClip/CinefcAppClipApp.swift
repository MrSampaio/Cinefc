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
                        "Escaneie a Tag NFC do filme",
                        systemImage: "iphone.radiowaves.left.and.right",
                        description: Text("Não encontramos um filme neste link.")
                    )
                } else {
                    ProgressView("Abrindo filme…")
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else { return }
                print("URL Recebida: ", url.absoluteString)
                
                // 1. Lógica correta para extrair da querystring "?id=2"
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems else {
                    print("URL inválida ou sem parâmetros")
                    return
                }
                
                if let idValue = queryItems.first(where: { $0.name == "id" })?.value {
                    print("O ID extraído da Tag NFC é: \(idValue)")
                    self.movieID = idValue
                } else {
                    self.movieID = DeepLink.movieID(from: url)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(3))
                if movieID == nil { timedOut = true }
            }
        }
    }
}
