//
//  ApplePayService.swift
//  TicketsClip
//
//  Created by Igor Carrasco on 28/10/26.
//

import PassKit

final class ApplePayService: NSObject, PKPaymentAuthorizationControllerDelegate {

    enum PayError: Error { case unavailable, cancelled, backendFailed }

    private let backend: OrderBackend
    private var continuation: CheckedContinuation<Order, Error>?
    private var controller: PKPaymentAuthorizationController?
    private var pendingShow: Show?
    private var pendingQuantity = 1
    private var completedOrder: Order?

    private let merchantID = "merchant.com.igorcarrasco.ticketspoc"
//    private let merchantID = "merchant.com.empresa.tickets"
    private let networks: [PKPaymentNetwork] = [.visa, .masterCard, .elo, .amex]

    init(backend: OrderBackend = MockOrderBackend()) {
        self.backend = backend
        super.init()
    }

    func pay(show: Show, quantity: Int) async throws -> Order {
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks) else {
            throw PayError.unavailable
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantID
        request.countryCode = "BR"
        request.currencyCode = "BRL"
        request.supportedNetworks = networks
        request.merchantCapabilities = .threeDSecure
        request.requiredShippingContactFields = [.emailAddress]

        let total = show.unitPrice * Decimal(quantity)
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "\(quantity)x \(show.title)",
                                 amount: NSDecimalNumber(decimal: total)),
            PKPaymentSummaryItem(label: "Bilheteria Empresa",
                                 amount: NSDecimalNumber(decimal: total))
        ]

        pendingShow = show
        pendingQuantity = quantity
        completedOrder = nil

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        self.controller = controller

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Order, Error>) in
            self.continuation = cont
            controller.present { presented in
                if !presented { self.finish(.failure(PayError.unavailable)) }
            }
        }
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard let show = pendingShow else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        let quantity = pendingQuantity

        Task {
            do {
                let order = try await self.backend.createOrder(
                    show: show,
                    quantity: quantity,
                    email: payment.shippingContact?.emailAddress,
                    paymentToken: payment.token.paymentData)
                self.completedOrder = order
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            } catch {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                if let order = self.completedOrder {
                    self.finish(.success(order))
                } else {
                    self.finish(.failure(PayError.cancelled))
                }
            }
        }
    }

    private func finish(_ result: Result<Order, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
    }
}

//import PassKit
//
//final class ApplePayService: NSObject, PKPaymentAuthorizationControllerDelegate {
//
//    enum PayError: Error { case unavailable, cancelled, backendFailed }
//
//    private var continuation: CheckedContinuation<Void, Error>?
//    private var controller: PKPaymentAuthorizationController?
//    private var didAuthorize = false
//
//    private let merchantID = "merchant.com.empresa.tickets"
//    private let networks: [PKPaymentNetwork] = [.visa, .masterCard, .elo, .amex]
//
//    func pay(show: Show, quantity: Int) async throws {
//        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks) else {
//            throw PayError.unavailable
//        }
//
//        let request = PKPaymentRequest()
//        request.merchantIdentifier = merchantID
//        request.countryCode = "BR"
//        request.currencyCode = "BRL"
//        request.supportedNetworks = networks
//        request.merchantCapabilities = .threeDSecure
//        // E-mail para envio do ingresso (sem cadastro no clip)
//        request.requiredShippingContactFields = [.emailAddress]
//
//        let total = show.unitPrice * Decimal(quantity)
//        request.paymentSummaryItems = [
//            PKPaymentSummaryItem(label: "\(quantity)x \(show.title)",
//                                 amount: NSDecimalNumber(decimal: total)),
//            // O último item é o total exibido na folha
//            PKPaymentSummaryItem(label: "Bilheteria Empresa",
//                                 amount: NSDecimalNumber(decimal: total))
//        ]
//
//        let controller = PKPaymentAuthorizationController(paymentRequest: request)
//        controller.delegate = self
//        self.controller = controller
//        didAuthorize = false
//
//        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
//            self.continuation = cont
//            controller.present { presented in
//                if !presented { self.finish(.failure(PayError.unavailable)) }
//            }
//        }
//    }
//
//    // MARK: - PKPaymentAuthorizationControllerDelegate
//
//    func paymentAuthorizationController(
//        _ controller: PKPaymentAuthorizationController,
//        didAuthorizePayment payment: PKPayment,
//        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
//    ) {
//        Task {
//            do {
//                // Em produção: envie payment.token.paymentData ao backend/PSP
//                try await self.sendToBackend(token: payment.token.paymentData,
//                                             email: payment.shippingContact?.emailAddress)
//                self.didAuthorize = true
//                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
//            } catch {
//                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
//            }
//        }
//    }
//
//    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
//        controller.dismiss {
//            DispatchQueue.main.async {
//                self.finish(self.didAuthorize ? .success(()) : .failure(PayError.cancelled))
//            }
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func finish(_ result: Result<Void, Error>) {
//        continuation?.resume(with: result)
//        continuation = nil
//        controller = nil
//    }
//
//    private func sendToBackend(token: Data, email: String?) async throws {
//        // PoC: simula latência. Na Etapa 4 plugamos o backend/PSP real.
//        print("Email do comprador:", email ?? "nil")
//        try await Task.sleep(for: .seconds(1))
//    }
//}
