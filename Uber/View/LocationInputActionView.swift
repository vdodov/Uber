//
//  LocationInputActionView.swift
//  Uber
//
//  Created by 차수연 on 2020/04/28.
//  Copyright © 2020 차수연. All rights reserved.
//

import UIKit

protocol LocationInputActionViewDelegate: class {
  func presentLocationInputView()
}

class LocationInputActionView: UIView {
  
  // MARK: - Properties
  
  weak var delegate: LocationInputActionViewDelegate?
  
  private let indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }()
  
  private let placeholderLabel: UILabel = {
    let label = UILabel()
    label.text = "Where to?"
    label.font = UIFont.systemFont(ofSize: 18)
    label.textColor = .darkGray
    return label
  }()
  
  // MARK: - LifeCycle
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    addShadow()
    
    addSubview(indicatorView)
    indicatorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
    indicatorView.setDimensions(height: 6, width: 6)
    
    addSubview(placeholderLabel)
    placeholderLabel.centerY(inView: self, leftAnchor: indicatorView.rightAnchor, paddingLeft: 20)
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(presentLocationInputView))
    addGestureRecognizer(tap)
  }
  
  // MARK: - Selectors
  @objc func presentLocationInputView() {
    delegate?.presentLocationInputView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
