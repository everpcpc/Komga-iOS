//
//  APIError.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

enum APIError: Error, CustomStringConvertible, LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(Int, String)
  case decodingError(Error)
  case unauthorized
  case networkError(Error)
  case badRequest(String)
  case forbidden(String)
  case notFound(String)
  case tooManyRequests(String)
  case serverError(String)

  var description: String {
    switch self {
    case .invalidURL:
      return "Invalid server URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let code, let message):
      return "Server error (\(code)): \(message)"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .unauthorized:
      return "Unauthorized. Please check your credentials."
    case .networkError(let error):
      if let nsError = error as NSError? {
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
          return "No internet connection. Please check your network settings."
        case NSURLErrorTimedOut:
          return "Request timed out. Please try again later."
        case NSURLErrorCancelled:
          return "Request cancelled"
        default:
          return "Network error: \(error.localizedDescription)"
        }
      }
      return "Network error: \(error.localizedDescription)"
    case .badRequest:
      return "Bad request"
    case .forbidden(let message):
      return "Forbidden: \(message)"
    case .notFound(let message):
      return "Not found: \(message)"
    case .tooManyRequests:
      return "Too many requests. Please try again later."
    case .serverError(let message):
      return "Server error: \(message)"
    }
  }

  var userMessage: String {
    switch self {
    case .invalidURL:
      return "Invalid server URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let code, _):
      return "Server error (\(code))"
    case .decodingError:
      return "Failed to process server response"
    case .unauthorized:
      return "Invalid credentials"
    case .networkError(let error):
      if let nsError = error as NSError? {
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
          return "No internet connection. Please check your network settings."
        case NSURLErrorTimedOut:
          return "Request timed out. Please try again later."
        case NSURLErrorCancelled:
          return ""  // Don't show cancelled errors
        default:
          return "Network error. Please check your connection."
        }
      }
      return "Network error. Please check your connection."
    case .badRequest:
      return "Invalid request"
    case .forbidden:
      return "Access denied. Please check your permissions."
    case .notFound:
      return "Resource not found"
    case .tooManyRequests:
      return "Too many requests. Please try again later."
    case .serverError:
      return "Server error. Please try again later."
    }
  }

  var errorDescription: String? {
    description
  }
}
