//
//  Uploader.swift
//  Uploader
//
//  Created by Ken Franklin
//  Copyright © 2022. All rights reserved.
//

import Foundation


class Uploader: NSObject, URLSessionTaskDelegate {
    static let shared = Uploader()
    
//    let bucket = "adiona-ephemeris"
//    let client = AWSClient(
//        credentialProvider: .static(accessKeyId: "AKIA5XA6KJBMLSDKEFZ3", secretAccessKey: "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"),
//        httpClientProvider: .createNew
//    )
//    var s3: S3
    
    override init() {
//        s3 = S3(client: client, region: .useast2)
        super.init()
    }
    
    func sendToS3(filename: String, json: String)  {
        
        
//         NSString *fileContentTypeStr = @"image/png";
//        AWSS3GetPreSignedURLRequest *urlRequest = [AWSS3GetPreSignedURLRequest new];
//        urlRequest.bucket = @"bounty-app";
//        urlRequest.key =[NSString stringWithFormat:@"submissions/photos/%@",nameOfImage];
//        urlRequest.HTTPMethod = AWSHTTPMethodPUT;
//        urlRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
//        urlRequest.contentType = fileContentTypeStr;
//        [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:urlRequest]
//         continueWithBlock:^id(BFTask *task) {
//
//             if (task.error) {
//                 NSLog(@"Error: %@",task.error);
//             } else {
//                 NSURL *presignedURL = task.result;
//                 NSLog(@"upload presignedURL is: \n%@", presignedURL);
//
//                 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
//                 request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
//                 [request setHTTPMethod:@"PUT"];
//                 [request setValue:fileContentTypeStr forHTTPHeaderField:@"Content-Type"];
//
//                 NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"unique_name_of_tttask"];
//                 NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
//                 NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromFile:savedPath];
//
//                 [uploadTask resume];
//             }
//             return nil;
//         }];
//        DispatchQueue.global().async {
//            do {
//                let putObjectRequest = S3.PutObjectRequest(
//                    body: .string(json),
//                    bucket: self.bucket,
//                    key: filename
//                )
//                let _ = try self.s3.putObject(putObjectRequest).wait()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
    }

    
    // MARK: - Properties
    
    var requestHttpHeaders = UploaderEntity()
    
    var urlQueryParameters = UploaderEntity()
    
    var httpBodyParameters = UploaderEntity()
    
    var httpBody: Data?
    
    // MARK: - Public Methods
    
    func makeRequest(toURL url: URL,
                     withHttpMethod httpMethod: HttpMethod,
                     completion: @escaping (_ result: Results) -> Void)
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURL: url)
            let httpBody = self?.getHttpBody()
            
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else {
                completion(Results(withError: CustomError.failedToCreateRequest))
                return
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: request) { data, response, error in
                completion(Results(withData: data,
                                   response: Response(fromURLResponse: response),
                                   error: error))
            }
            task.resume()
        }
    }
    
    func getData(fromURL url: URL, completion: @escaping (_ data: Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: url, completionHandler: { data, _, _ in
                guard let data = data else { completion(nil); return }
                completion(data)
            })
            task.resume()
        }
    }
    
    func upload(file: FileInfo, toURL url: URL,
                withHttpMethod httpMethod: HttpMethod,
                completion: @escaping (_ result: Results, _ failedFiles: [String]?) -> Void)
    {
        let targetURL = addURLQueryParameters(toURL: url)
        guard let boundary = createBoundary() else { completion(Results(withError: CustomError.failedToCreateBoundary), nil); return }
        requestHttpHeaders.add(value: "multipart/form-data; boundary=\(boundary)", forKey: "content-type")

        var body = getHttpBody(withBoundary: boundary)
        //let failedFilenames = self?.add(files: [file], toBody: &body, withBoundary: boundary)
        close(body: &body, usingBoundary: boundary)

        guard let request = prepareRequest(withURL: targetURL, httpBody: body, httpMethod: httpMethod) else { completion(Results(withError: CustomError.failedToCreateRequest), nil); return }
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let task = session.uploadTask(with: request, fromFile: file.url)
        task.resume()
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
    // MARK: - Private Methods

    
    private func addURLQueryParameters(toURL url: URL) -> URL {
        if urlQueryParameters.totalItems() > 0 {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                
                queryItems.append(item)
            }
            
            urlComponents.queryItems = queryItems
            
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        
        return url
    }
    
    private func getHttpBody() -> Data? {
        guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else { return nil }
        
        if contentType.contains("application/json") {
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        } else {
            return httpBody
        }
    }
    
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        for (header, value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        request.httpBody = httpBody
        return request
    }
}

// MARK: - RestManager Custom Types

extension Uploader {
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }

    struct UploaderEntity {
        private var values: [String: String] = [:]
        
        mutating func add(value: String, forKey key: String) {
            values[key] = value
        }
        
        func value(forKey key: String) -> String? {
            return values[key]
        }
        
        func allValues() -> [String: String] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }
    }
    
    struct Response {
        var response: URLResponse?
        var httpStatusCode: Int = 0
        var headers = UploaderEntity()
        
        init(fromURLResponse response: URLResponse?) {
            guard let response = response else { return }
            self.response = response
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value) in headerFields {
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
    }
    
    struct Results {
        var data: Data?
        var response: Response?
        var error: Error?
        
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error) {
            self.error = error
        }
    }

    enum CustomError: Error {
        case failedToCreateRequest
        case failedToCreateBoundary
        case failedToCreateHttpBody
    }
}

// MARK: - Custom Error Description

extension Uploader.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        case .failedToCreateBoundary: return NSLocalizedString("Unable to create boundary string", comment: "")
        case .failedToCreateHttpBody: return NSLocalizedString("Unable to create HTTP body parameters data", comment: "")
        }
    }
}

// MARK: - File Upload Related Implementation

extension Uploader {
    struct FileInfo {
        var fileContents: Data?
        var mimetype: String?
        var filename: String?
        var name: String?
        var url: URL
        init(withFileURL url: URL, filename: String, name: String, mimetype: String) {
            self.url = url
            fileContents = try? Data(contentsOf: url)
            self.filename = filename
            self.name = name
            self.mimetype = mimetype
        }
    }
    
    private func createBoundary() -> String? {
        // Uncomment the following lines to create a boundary
        // string using a UUID value. Do not forget to comment out
        // the second way!
        /*
         var uuid = UUID().uuidString
         uuid = uuid.replacingOccurrences(of: "-", with: "")
         uuid = uuid.map { $0.lowercased() }.joined()
        
         let boundary = String(repeating: "-", count: 20) + uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"
        
         return boundary
         */
        
        // This is the second way to create a random string to use
        // with the boundary string. Comment out the following lines
        // if you want to use the first approach above!
        let lowerCaseLettersInASCII = UInt8(ascii: "a")...UInt8(ascii: "z")
        let upperCaseLettersInASCII = UInt8(ascii: "A")...UInt8(ascii: "Z")
        let digitsInASCII = UInt8(ascii: "0")...UInt8(ascii: "9")
        
        let sequenceOfRanges = [lowerCaseLettersInASCII, upperCaseLettersInASCII, digitsInASCII].joined()
        guard let toString = String(data: Data(sequenceOfRanges), encoding: .utf8) else { return nil }
        
        var randomString = ""
        for _ in 0 ..< 20 { randomString += String(toString.randomElement()!) }
        
        let boundary = String(repeating: "-", count: 20) + randomString + "\(Int(Date.timeIntervalSinceReferenceDate))"
        
        return boundary
    }
    
    private func getHttpBody(withBoundary boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in httpBodyParameters.allValues() {
            let values = ["--\(boundary)\r\n",
                          "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
                          "\(value)\r\n"]
            
            _ = body.append(values: values)
        }
        
        return body
    }
    
    private func add(files: [FileInfo], toBody body: inout Data, withBoundary boundary: String) -> [String]? {
        var status = true
        var failedFilenames: [String]?
        
        for file in files {
            guard let filename = file.filename, let content = file.fileContents, let mimetype = file.mimetype, let name = file.name else { continue }
            
            status = false
            var data = Data()
            
            let formattedFileInfo = ["--\(boundary)\r\n",
                                     "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n",
                                     "Content-Type: \(mimetype)\r\n\r\n"]
            
            if data.append(values: formattedFileInfo) {
                if data.append(values: [content]) {
                    if data.append(values: ["\r\n"]) {
                        status = true
                    }
                }
            }
            
            if status {
                body.append(data)
            } else {
                if failedFilenames == nil {
                    failedFilenames = [String]()
                }
                
                failedFilenames?.append(filename)
            }
        }
        
        return failedFilenames
    }
    
    private func close(body: inout Data, usingBoundary boundary: String) {
        _ = body.append(values: ["\r\n--\(boundary)--\r\n"])
    }
}

// MARK: - Data Extension

extension Data {
    mutating func append<T>(values: [T]) -> Bool {
        var newData = Data()
        var status = true
        
        if T.self == String.self {
            for value in values {
                guard let convertedString = (value as! String).data(using: .utf8) else { status = false; break }
                newData.append(convertedString)
            }
        } else if T.self == Data.self {
            for value in values {
                newData.append(value as! Data)
            }
        } else {
            status = false
        }
        
        if status {
            append(newData)
        }
        
        return status
    }
}
