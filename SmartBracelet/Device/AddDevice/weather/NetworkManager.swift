//
//  NetworkManager.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 27.06.2022.
//

import Foundation
import CoreLocation

enum NetworkError {
    case failedURL
    case parsingError
    case emptyData
}

class NetworkManager {
    enum RequestType {
        case cityName(city: String)
        case coordinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
    }

    func fetchData(
        requestType: RequestType,
        onCompletion: @escaping ((CurrentWeatherData) -> Void),
        onError: @escaping ((NetworkError) -> Void)
    ) {
        guard let url = createURLcomponents(requestType: requestType) else {
            onError(.failedURL)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    if let note = try self.parseJSON(withData: data) {
                        onCompletion(note)
                    }
                } catch {
                    onError(.parsingError)
                }
            } else {
                onError(.emptyData)
            }
        }.resume()
    }

    private func createURLcomponents(requestType: RequestType) -> URL? {
        var urlComponents = URLComponents()

        urlComponents.scheme = "https"
        urlComponents.host = "api.openweathermap.org"
        urlComponents.path = "/data/2.5/forecast/daily"
        switch requestType {
        case .cityName(let city):
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: city),
                URLQueryItem(name: "appid", value: Constant.keyAPI),
                URLQueryItem(name: "units", value: "metric")
            ]
        case .coordinate(let latitude, let longitude):
            urlComponents.queryItems = [
                URLQueryItem(name: "lat", value: "\(latitude)"),
                URLQueryItem(name: "lon", value: "\(longitude)"),
                URLQueryItem(name: "appid", value: Constant.keyAPI)
            ]
        }
        return urlComponents.url
    }

    private func parseJSON(withData data: Data) throws -> CurrentWeatherData? {
        let decoder = JSONDecoder()
        let noteData = try decoder.decode(CurrentWeatherData.self, from: data)
        return noteData
    }
}


/*{\"city\":{\"id\":6942880,\"name\":\"Haikuotiankong\",\"coord\":{\"lon\":113.9623,\"lat\":22.5368},\"country\":\"CN\",\"population\":2100,\"timezone\":28800},\"cod\":\"200\",\"message\":31.864873,\"cnt\":7,\"list\":[{\"dt\":1656820800,\"sunrise\":1656798216,\"sunset\":1656846760,\"temp\":{\"day\":301.89,\"min\":300.34,\"max\":302.31,\"night\":300.8,\"eve\":301.25,\"morn\":300.5},\"feels_like\":{\"day\":307.38,\"night\":305.66,\"eve\":307.03,\"morn\":304.15},\"pressure\":1002,\"humidity\":81,\"weather\":[{\"id\":501,\"main\":\"Rain\",\"description\":\"moderate rain\",\"icon\":\"10d\"}],\"speed\":11.06,\"deg\":169,\"gust\":17.22,\"clouds\":100,\"pop\":1,\"rain\":16.25},{\"dt\":1656907200,\"sunrise\":1656884636,\"sunset\":1656933160,\"temp\":{\"day\":299.07,\"min\":298.92,\"max\":300.58,\"night\":299.61,\"eve\":299.66,\"morn\":299.53},\"feels_like\":{\"day\":300.22,\"night\":299.61,\"eve\":299.66,\"morn\":299.53},\"pressure\":1002,\"humidity\":96,\"weather\":[{\"id\":502,\"main\":\"Rain\",\"description\":\"heavy intensity rain\",\"icon\":\"10d\"}],\"speed\":8.46,\"deg\":202,\"gust\":13.48,\"clouds\":100,\"pop\":1,\"rain\":45.58},{\"dt\":1656993600,\"sunrise\":1656971057,\"sunset\":1657019560,\"temp\":{\"day\":300.63,\"min\":299.31,\"max\":300.89,\"night\":299.56,\"eve\":300.24,\"morn\":299.45},\"feels_like\":{\"day\":304.36,\"night\":299.56,\"eve\":303.92,\"morn\":299.45},\"pressure\":1004,\"humidity\":83,\"weather\":[{\"id\":501,\"main\":\"Rain\",\"description\":\"moderate rain\",\"icon\":\"10d\"}],\"speed\":6.02,\"deg\":179,\"gust\":10.05,\"clouds\":100,\"pop\":1,\"rain\":15.7},{\"dt\":1657080000,\"sunrise\":1657057478,\"sunset\":1657105958,\"temp\":{\"day\":301.3,\"min\":298.8,\"max\":301.3,\"night\":298.8,\"eve\":298.91,\"morn\":299.62},\"feels_like\":{\"day\":306.13,\"night\":299.9,\"eve\":300.02,\"morn\":299.62},\"pressure\":1005,\"humidity\":83,\"weather\":[{\"id\":501,\"main\":\"Rain\",\"description\":\"moderate rain\",\"icon\":\"10d\"}],\"speed\":6.71,\"deg\":220,\"gust\":8.64,\"clouds\":100,\"pop\":1,\"rain\":32.34},{\"dt\":1657166400,\"sunrise\":1657143900,\"sunset\":1657192355,\"temp\":{\"day\":298.62,\"min\":298.46,\"max\":299.05,\"night\":299,\"eve\":299.05,\"morn\":298.81},\"feels_like\":{\"day\":299.68,\"night\":300.07,\"eve\":300.1,\"morn\":299.83},\"pressure\":1005,\"humidity\":94,\"weather\":[{\"id\":502,\"main\":\"Rain\",\"description\":\"heavy intensity rain\",\"icon\":\"10d\"}],\"speed\":7.11,\"deg\":215,\"gust\":11.05,\"clouds\":100,\"pop\":1,\"rain\":47.49},{\"dt\":1657252800,\"sunrise\":1657230322,\"sunset\":1657278752,\"temp\":{\"day\":299.51,\"min\":298.61,\"max\":299.51,\"night\":298.65,\"eve\":298.78,\"morn\":298.88},\"feels_like\":{\"day\":299.51,\"night\":299.61,\"eve\":299.77,\"morn\":299.91},\"pressure\":1007,\"humidity\":90,\"weather\":[{\"id\":501,\"main\":\"Rain\",\"description\":\"moderate rain\",\"icon\":\"10d\"}],\"speed\":3.75,\"deg\":141,\"gust\":5.36,\"clouds\":99,\"pop\":1,\"rain\":9},{\"dt\":1657339200,\"sunrise\":1657316745,\"sunset\":1657365147,\"temp\":{\"day\":302.08,\"min\":298.57,\"max\":302.5,\"night\":300.43,\"eve\":302.2,\"morn\":298.59},\"feels_like\":{\"day\":307.49,\"night\":304.45,\"eve\":307.17,\"morn\":299.57},\"pressure\":1007,\"humidity\":79,\"weather\":[{\"id\":500,\"main\":\"Rain\",\"description\":\"light rain\",\"icon\":\"10d\"}],\"speed\":4.13,\"deg\":173,\"gust\":4.88,\"clouds\":94,\"pop\":0.91,\"rain\":1.99}]}*/
