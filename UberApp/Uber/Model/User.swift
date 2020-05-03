//
//  User.swift
//  Uber
//
//  Created by 차수연 on 2020/04/29.
//  Copyright © 2020 차수연. All rights reserved.
//

import CoreLocation

struct User {
  let uid: String
  let fullname: String
  let email: String
  let accountType: Int
  var location: CLLocation?
  
  init(uid: String, dictionary: [String: Any]) {
    self.uid = uid
    self.fullname = dictionary["fullname"] as? String ?? ""
    self.email = dictionary["email"] as? String ?? ""
    self.accountType = dictionary["accountType"] as? Int ?? 0
  }
  
}
