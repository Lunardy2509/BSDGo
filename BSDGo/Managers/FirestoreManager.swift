//
//  FirestoreManager.swift
//  BSDGo
//
//  Created by Ferdinand Lunardy on 20/01/2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreManager {
    
    static let shared = FirestoreManager()
    private lazy var db = Firestore.firestore()
    
    private var cachedBuses: [Bus]?
    private var cachedSchedules: [BusSchedule]?
    private var cachedStops: [BusStop]?
    
    private init() { }
    
    // MARK: Load Buses Data
    func fetchBuses(refresh: Bool = false, completion: @escaping (Result<[Bus], Error>) -> Void) {
        
        // Check Cache
        if let cached = cachedBuses, !refresh {
            completion(.success(cached))
            return
        }
        
        // Fetch from Network
        db.collection("buses").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.success([]))
                return
            }
            
            let buses: [Bus] = snapshot.documents.compactMap { doc in
                var bus = try? doc.data(as: Bus.self)
                bus?.firestoreID = doc.documentID
                return bus
            }
            // Save to Cache
            self?.cachedBuses = buses
            completion(.success(buses))
        }
    }
    
    // MARK: Load Bus Schedules Data
    func fetchSchedules(refresh: Bool = false, completion: @escaping (Result<[BusSchedule], Error>) -> Void) {
        
        if let cached = cachedSchedules, !refresh {
            completion(.success(cached))
            return
        }
        
        db.collection("schedules").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.success([]))
                return
            }
            
            let schedules: [BusSchedule] = snapshot.documents.compactMap { doc in
                var schedule = try? doc.data(as: BusSchedule.self)
                schedule?.firestoreID = doc.documentID
                return schedule
            }
            
            self?.cachedSchedules = schedules
            completion(.success(schedules))
        }
    }
    
    // MARK: Load Bus Stops Data
    func fetchStops(refresh: Bool = false, completion: @escaping (Result<[BusStop], Error>) -> Void) {
        
        if let cached = cachedStops, !refresh {
            completion(.success(cached))
            return
        }
        
        db.collection("stops").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.success([]))
                return
            }
            
            let stops: [BusStop] = snapshot.documents.compactMap { doc in
                let stop = try? doc.data(as: BusStop.self)
                return stop
            }
            
            self?.cachedStops = stops
            completion(.success(stops))
        }
    }
    
    // Call this in the App Delegate or Root View .onAppear to load EVERYTHING once
    func preloadAllData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        fetchBuses { _ in group.leave() }
            
        fetchSchedules { _ in group.leave() }
        
        fetchStops { _ in group.leave() }
        
        group.notify(queue: .main) {
            completion()
        }
    }
}
