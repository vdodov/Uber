//
//  DriverAnnotation.swift
//  Uber
//
//  Created by 차수연 on 2020/04/29.
//  Copyright © 2020 차수연. All rights reserved.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
  dynamic var coordinate: CLLocationCoordinate2D
  var uid: String
  
  init(uid: String, coordinate: CLLocationCoordinate2D){
    self.uid = uid
    self.coordinate = coordinate
  }
  
  func updateAnnotationPostion(withCoordinate coordinate: CLLocationCoordinate2D) {
    UIView.animate(withDuration: 0.2) {
      self.coordinate = coordinate
    }
  }
  
}
