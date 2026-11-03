//
//  ReadMovie.swift
//  Cinefc
//
//  Created by Julio Sampaio on 03/11/26.
//

import CoreNFC

final class NFCMovieReader: NSObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    
    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else {
            return
        }
        
        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        
        session?.alertMessage =
        "Aproxime o iPhone da tag presente no cartaz do filme."
        
        session?.begin()
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        guard
            let record = messages.first?.records.first,
            let url = record.wellKnownTypeURIPayload()
                else {
            session.invalidate(errorMessage: "Tag inválida.")
            return
        }
        
        guard
            url.host == "cinefc.com",
            url.pathComponents.contains("filmes"),
            let movieID = url.pathComponents.last
                else {
            session.invalidate(errorMessage: "Tag não reconhecida.")
            return
        }
        
        session.alertMessage = "Filme identificado."
        session.invalidate()
        
        Task { @MainActor in
            // movieService.fetchMovie(id: movieID)
        }
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
        // Tratar cancelamento, indisponibilidade ou tempo esgotado.
    }
}
