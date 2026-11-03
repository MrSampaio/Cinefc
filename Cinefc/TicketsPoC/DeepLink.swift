//
//  DeepLink.swift
//  TicketsPoC
//
//  Created by Igor Carrasco on 28/10/26.
//

import Foundation

enum DeepLink {
    static func showID(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "id" })?
            .value
    }
}
