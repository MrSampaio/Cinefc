//
//  ApplePayService.swift
//  CinefcAppClip
//

import Foundation
import PassKit

@MainActor
final class ApplePayService: NSObject, PKPaymentAuthorizationControllerDelegate {
    
    enum PayError: Error, Equatable, LocalizedError {
        case unavailable
        case cancelled
        case presentationFailed
        case paymentFailed
        
        var errorDescription: String? {
            switch self {
                case .unavailable:
                    return "O Apple Pay não está disponível neste dispositivo."
                    
                case .cancelled:
                    return "Pagamento cancelado."
                    
                case .presentationFailed:
                    return "Não foi possível abrir o Apple Pay."
                    
                case .paymentFailed:
                    return "Não foi possível concluir o pagamento."
            }
        }
    }
    
    private let merchantID = "merchant.com.juliosampaio.cinefc"
    
    private let supportedNetworks: [PKPaymentNetwork] = [
        .visa,
        .masterCard,
        .amex,
        .elo
    ]
    
    private var paymentController: PKPaymentAuthorizationController?
    private var continuation: CheckedContinuation<Order, Error>?
    
    private var pendingShow: Show?
    private var pendingQuantity = 0
    private var completedOrder: Order?
    
    private var presentationDidFail = false
    
    func pay(show: Show, quantity: Int) async throws -> Order {
        print("ApplePayService.pay foi chamado")
        print("Quantidade:", quantity)
        print("Merchant ID:", merchantID)
        
        guard quantity > 0 else {
            print("Quantidade inválida")
            throw PayError.paymentFailed
        }
        
        let supportsApplePay =
        PKPaymentAuthorizationController.canMakePayments()
        
        print("Dispositivo suporta Apple Pay:", supportsApplePay)
        
        guard supportsApplePay else {
            throw PayError.unavailable
        }
        
        // verifica se tem cartão disponível e se ta buildado no iphone ou no simulador
#if !targetEnvironment(simulator)
        let hasCompatibleCard =
        PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: supportedNetworks,
            capabilities: .threeDSecure
        )
        
        print("Existe cartão compatível:", hasCompatibleCard)
        
        guard hasCompatibleCard else {
            throw PayError.unavailable
        }
#else
        print("Executando no Simulator")
#endif
        
        // faz os cálculos do valor total
        let total = show.unitPrice * Decimal(quantity)
        
        print("Valor unitário:", show.unitPrice)
        print("Total:", total)
        
        let request = PKPaymentRequest()
        
        request.merchantIdentifier = merchantID
        request.countryCode = "BR"
        request.currencyCode = "BRL"
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = [.threeDSecure]
        
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "\(quantity)x \(show.title)",
                amount: NSDecimalNumber(decimal: total),
                type: .final
            ),
            
            PKPaymentSummaryItem(
                label: "CineFC",
                amount: NSDecimalNumber(decimal: total),
                type: .final
            )
        ]
        
        pendingShow = show
        pendingQuantity = quantity
        completedOrder = nil
        presentationDidFail = false
        
        let controller = PKPaymentAuthorizationController(
            paymentRequest: request
        )
        
        controller.delegate = self
        paymentController = controller
        
        return try await withCheckedThrowingContinuation {
            (currentContinuation: CheckedContinuation<Order, Error>) in
            
            continuation = currentContinuation
            
//            print("tentando apresentar a sheet")
            
            controller.present { [weak self] presented in
                guard let self else {
                    return
                }
                
//                print("resultado do present:", presented)
                
                if !presented {
                    Task { @MainActor in
                        self.presentationDidFail = true
                        
                        self.finish(
                            .failure(PayError.presentationFailed)
                        )
                    }
                }
            }
        }
    }

    // valida o status da autorização do pagamento
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
//        print("didAuthorizePayment aqui")
        
        guard let show = pendingShow else {
//            print("Erro: pendingShow está nil")
            
            completion(
                PKPaymentAuthorizationResult(
                    status: .failure,
                    errors: [PayError.paymentFailed]
                )
            )
            
            return
        }
        
        let quantity = pendingQuantity
        
        guard quantity > 0 else {
            print("erro: pendingQuantity está inválido:", quantity)
            
            completion(
                PKPaymentAuthorizationResult(
                    status: .failure,
                    errors: [PayError.paymentFailed]
                )
            )
            
            return
        }
//        
//        print("Criando pedido simulado")
//        print("Filme:", show.title)
//        print("Quantidade:", quantity)
//        print(
//            "Token recebido:",
//            payment.token.paymentData.count,
//            "bytes"
//        )
        
        let ticketCode =
        "TKT-" +
        String(UUID().uuidString.prefix(8)).uppercased()
        
        let order = Order(
            id: UUID().uuidString,
            ticketCode: ticketCode,
            showTitle: show.title,
            quantity: quantity,
            email: nil
        )
        

        // o pedido tem que ser armazenado
        completedOrder = order

        
        completion(
            PKPaymentAuthorizationResult(
                status: .success,
                errors: nil
            )
        )
    }
    
    func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        
        controller.dismiss { [weak self] in
            guard let self else {
                return
            }
            
            // task que verifica se o pagamento finalizou com sucesso ou não
            Task { @MainActor in
                if self.presentationDidFail {
//                    print("DidFinish ignoraou")
                    return
                }
                
                if let order = self.completedOrder {
//                    print("apple pay fechado, amém")
                    
                    self.finish(.success(order))
                } else {
//                    print("cancelado")
                    
                    self.finish(
                        .failure(PayError.cancelled)
                    )
                }
            }
        }
    }
    
    // finaliza a operação de compra
    private func finish(_ result: Result<Order, Error>) {
        guard let currentContinuation = continuation else {
            return
        }
        
        continuation = nil
        paymentController = nil
        pendingShow = nil
        pendingQuantity = 0
        
        currentContinuation.resume(with: result)
    }
    
    func simulatePayment(
        show: Show,
        quantity: Int
    ) async throws -> Order {
        
        guard quantity > 0 else {
            throw PayError.paymentFailed
        }
        
        try await Task.sleep(for: .seconds(1))
        
        // simula o codigo
        let ticketCode =
        "TKT-" +
        String(UUID().uuidString.prefix(8)).uppercased()
        
        let order = Order(
            id: UUID().uuidString,
            ticketCode: ticketCode,
            showTitle: show.title,
            quantity: quantity,
            email: nil
        )
        
        print("pedido:", order.id)
        print("código:", order.ticketCode)
        
        return order
    }
}
