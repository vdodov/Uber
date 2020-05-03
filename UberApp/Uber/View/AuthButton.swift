//
//  AuthButton.swift
//  Uber
//
//  Created by 차수연 on 2020/04/27.
//  Copyright © 2020 차수연. All rights reserved.
//

import UIKit

class AuthButton: UIButton {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  
    setTitleColor(UIColor(white: 1, alpha: 0.5), for: .normal)
    backgroundColor = .mainBlueTint
    layer.cornerRadius = 5
    heightAnchor.constraint(equalToConstant: 50).isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
