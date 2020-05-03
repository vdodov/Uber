//
//  LocationHandler.swift
//  Uber
//
//  Created by 차수연 on 2020/04/29.
//  Copyright © 2020 차수연. All rights reserved.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
  static let shared = LocationHandler()
  var locationManager: CLLocationManager!
  var location: CLLocation?
  
  override init() {
    super.init()
    
    locationManager = CLLocationManager()
    locationManager.delegate = self
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
    if status == .authorizedWhenInUse {
      locationManager.requestAlwaysAuthorization()
    }
  }
  
  
}
