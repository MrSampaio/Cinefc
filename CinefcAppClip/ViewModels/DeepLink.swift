//
//  DeepLink.swift
//  TicketsPoC
//
//  Created by Igor Carrasco on 28/10/26.
//

import Foundation

// extrai o ID do filme pela URL recebida via tag NFC (Deep Link)
enum DeepLink {
    static func movieID(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "id" })?
            .value
    }
}


