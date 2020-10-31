//
//  LocationRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

/// The following class define a single location request.
public class GPSLocationRequest: RequestProtocol, Codable {
    public typealias ProducedData = CLLocation
    
    /// Unique identifier of the request.
    public var uuid: Identifier = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// `true` if request is enabled.
    public var isEnabled: Bool = true

    /// Options for location
    public var options: GPSLocationOptions

    /// Registered callbacks which receive events.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Number of valid data received.
    public var countReceivedData = 0
    
    /// Last valid received location from underlying service.
    /// NOTE: Until the first valid result value is `nil.`
    public private(set) var lastLocation: CLLocation?

    /// Last received value from underlying service.
    /// It may also an error, if it's a value its the same of `lastLocation`.
    public var lastReceivedValue: (Result<CLLocation, LocatorErrors>)?

    /// This is the default policy which manage the auto-cancel of a request from queue.
    /// The default implementation different based upon the type of subscription:
    /// - if subscription is `continous` no auto-cancel settings, no evitionPolicy is set and you must remove the request manually.
    /// - if subscription is `single` it will be removed when an error occours (which is not `discardedData`) or first valid result received.
    public var evictionPolicy: Set<RequestEvictionPolicy> {
        set {
            guard options.subscription == .single else {
                _evictionPolicy = newValue // just pass the value.
                return
            }
            // NOTE: For single subscription we must ignore each custom eviction based upon the number of data received
            // Single subscriptions ends at the first valid result, always.
            _evictionPolicy = newValue.filter({ !$0.isReceiveDataEviction })
            _evictionPolicy.insert(.onReceiveData(count: 1))
        }
        get {
            return _evictionPolicy
        }
    }
        
    // MARK: - Private Properties
    
    /// See `evictionPolicy`.
    private var _evictionPolicy = Set<RequestEvictionPolicy>()
    
    /// Timeout timer.
    private var timeoutTimer: Timer?
    
    // MARK: - Codable
        
    enum CodingKeys: String, CodingKey {
        case uuid, isEnabled, options, lastReceivedValue, timeoutTimer, name
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(options, forKey: .options)
        try container.encodeIfPresent(name, forKey: .name)
    }
    
    // Decodable protocol
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.options = try container.decode(GPSLocationOptions.self, forKey: .options)
        self.options.request = self
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
     
    // MARK: - Initialization
    
    /// Initialize.
    /// - Parameter locationOptions: custom options to use.
    internal init(_ locationOptions: GPSLocationOptions? = nil) {
        self.options = locationOptions ?? GPSLocationOptions()
        self.options.request = self
        
        if options.subscription == .single {
            self.evictionPolicy = [.onError, .onReceiveData(count: 1)]
        }
    }
    
    public static func == (lhs: GPSLocationRequest, rhs: GPSLocationRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    // MARK: - Public Functions

    public func validateData(_ data: ProducedData) -> DataDiscardReason? {
        guard isEnabled else {
            return .requestNotEnabled // request is not enabled so we'll discard data.
        }
        
        guard data.horizontalAccuracy <= options.accuracy.value else {
            return .notMinAccuracy // accuracy level is below the minimum set
        }
        
        if let previousLocation = lastLocation {
            if let minDistance = options.minDistance,
               previousLocation.distance(from: data) > minDistance {
                return .notMinDistance // minimum distance since last location is not respected.
            }
            
            if let minInterval = options.minTimeInterval,
               previousLocation.timestamp.timeIntervalSince(Date()) >= minInterval {
                return .notMinInterval // minimum time interval since last location is not respected.
            }
        }
        
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        guard let timeout = options.timeout, // has valid timeout settings
              timeout.canFireTimer, // can fire the timer (timeout is immediate or delayed with auth ok)
              timeoutTimer == nil else { // timer never started yet for this request
            return
        }
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout.interval, repeats: false, block: { [weak self] timer in
            timer.invalidate()
            self?.receiveData(.failure(.timeout))
        })
    }
    
    public var description: String {
        JSONStringify([
            "uuid" : uuid,
            "name": name ?? "",
            "enabled": isEnabled,
            "options": options.description,
            "subscriptions": subscriptions.count,
            "lastValue": lastReceivedValue?.description ?? "",
            "timeout": timeoutTimer?.description ?? ""
        ])
    }
    
}

// MARK: - Result<CLLocation,LocatorErrors>

extension Result where Success == CLLocation, Failure == LocatorErrors {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let location):
            return "Success \(location.description)"
        }
    }
    
}
