//
//  Order.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 29/10/26.
//

import Foundation

struct Order: Equatable {
    let id: String
    let ticketCode: String
    let showTitle: String
    let quantity: Int
    let email: String?
}
