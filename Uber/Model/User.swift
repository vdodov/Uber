//
//  User.swift
//  Uber
//
//  Created by 차수연 on 2020/04/29.
//  Copyright © 2020 차수연. All rights reserved.
//

import CoreLocation

enum AccountType: Int {
  case passenger
  case driver
}

struct User {
  let uid: String
  let fullname: String
  let email: String
  var accountType: AccountType!
  var location: CLLocation?
  
  init(uid: String, dictionary: [String: Any]) {
    self.uid = uid
    self.fullname = dictionary["fullname"] as? String ?? ""
    self.email = dictionary["email"] as? String ?? ""
    
    if let index = dictionary["accountType"] as? Int {
      self.accountType = AccountType(rawValue: index)
    }
  }
  
}
