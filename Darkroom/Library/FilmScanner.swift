//
//  FilmScanner.swift
//  Darkroom
//
//  Reading a canister from a photograph: Vision's text recognition for the
//  printed name and ISO, and its barcode detection for anything it can decode.
//  The DX code printed on most canisters is not a standard barcode, so the text
//  it reads is what does the work — and the screen says so.
//

import ImageIO
import SwiftUI
import UIKit
import Vision

enum FilmScan {
    struct Reading {
        let texts: [String]
        let barcodes: [String]

        static let empty = Reading(texts: [], barcodes: [])

        var isEmpty: Bool { texts.isEmpty && barcodes.isEmpty }
    }

    static func read(_ image: UIImage) async -> Reading {
        guard let cgImage = image.cgImage else { return .empty }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation,
                    options: [:]
                )

                let textRequest = VNRecognizeTextRequest()
                textRequest.recognitionLevel = .accurate
                textRequest.usesLanguageCorrection = true

                let barcodeRequest = VNDetectBarcodesRequest()

                do {
                    try handler.perform([textRequest, barcodeRequest])
                } catch {
                    continuation.resume(returning: .empty)
                    return
                }

                let texts = (textRequest.results ?? []).compactMap {
                    $0.topCandidates(1).first?.string
                }
                let barcodes = (barcodeRequest.results ?? []).compactMap {
                    $0.payloadStringValue
                }

                continuation.resume(returning: Reading(texts: texts, barcodes: barcodes))
            }
        }
    }
}

// MARK: - Camera

struct FilmCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: FilmCameraPicker

        init(_ parent: FilmCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Orientation

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
