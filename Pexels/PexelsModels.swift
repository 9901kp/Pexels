//
//  PexelsModels.swift
//  Pexels
//
//  Auto-created to provide missing models for decoding Pexels API responses.
//

import Foundation

enum PexelsAPI {
    // Top-level response for the search endpoint: https://api.pexels.com/v1/search
    // Only the fields used by the app are modeled here.
    struct SearchPhotosResponse: Decodable {
        let page: Int?
        let perPage: Int?
        let photos: [Photo]

        private enum CodingKeys: String, CodingKey {
            case page
            case perPage = "per_page"
            case photos
        }
    }

    // Represents a single photo entry in the response
    struct Photo: Decodable {
        let id: Int
        let width: Int?
        let height: Int?
        let url: String?
        let photographer: String?
        let src: PhotoSrc
    }

    // URLs for various sizes. We expose `large2X` to match existing usage in MainViewController,
    // while decoding the API's `large2x` key.
    struct PhotoSrc: Decodable {
        let original: String?
        let large2X: String
        let large: String?
        let medium: String?
        let small: String?
        let portrait: String?
        let landscape: String?
        let tiny: String?

        private enum CodingKeys: String, CodingKey {
            case original
            case large2X = "large2x"
            case large
            case medium
            case small
            case portrait
            case landscape
            case tiny
        }
    }
}
