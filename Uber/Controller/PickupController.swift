//
//  PickupController.swift
//  Uber
//
//  Created by 차수연 on 2020/05/04.
//  Copyright © 2020 차수연. All rights reserved.
//

import UIKit
import MapKit

protocol PickupControllerDelegate: class {
  func didAcceptTrip(_ trip: Trip)
}

class PickupController: UIViewController {
  
  // MARK: - Properties
  
  weak var delegate: PickupControllerDelegate?
  
  private let mapView = MKMapView()
  let trip: Trip
  
  private let cancelButton: UIButton = {
    let button = UIButton()
    button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
    button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
    return button
  }()
  
  private let pickupLabel: UILabel = {
    let label = UILabel()
    label.text = "Would you like to pickup this passenger?"
    label.font = UIFont.systemFont(ofSize: 16)
    label.textColor = .white
    return label
  }()
  
  private let acceptTripButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .white
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
    button.setTitle("ACCEPT TRIP", for: .normal)
    button.setTitleColor(.black, for: .normal)
    button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
    return button
  }()
  
  // MARK: - LifeCycle
  
  init(trip: Trip) {
    self.trip = trip
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    print("DEBUG: Trip passenger uid is \(trip.passengerUid)")
    
    configureUI()
    configureMapView()
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  // MARK: - Selectors
  
  @objc func handleAcceptTrip() {
    Service.shared.acceptTrip(trip: trip) { (error, ref) in
      self.delegate?.didAcceptTrip(self.trip)
    }
  }
  
  @objc func handleDismissal() {
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - API
  
  // MARK: - Helper Functions
  
  func configureMapView() {
    let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
    mapView.setRegion(region, animated: false)
    
    let anno = MKPointAnnotation()
    anno.coordinate = trip.pickupCoordinates
    mapView.addAnnotation(anno)
    self.mapView.selectAnnotation(anno, animated: true)
    
  }
  
  func configureUI() {
    view.backgroundColor = .black
    
    view.addSubview(cancelButton)
    cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingLeft: 16)
    
    view.addSubview(mapView)
    mapView.setDimensions(height: 270, width: 270)
    mapView.layer.cornerRadius = 270 / 2
    mapView.centerX(inView: view)
    mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 40)// centerY가 잡히지 않아서 임의로 값을 줌
    
    view.addSubview(pickupLabel)
    pickupLabel.centerX(inView: view)
    pickupLabel.anchor(top: mapView.bottomAnchor, paddingTop: 16)
    
    view.addSubview(acceptTripButton)
    acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                            paddingTop: 16, paddingLeft: 32, paddingRight: 32, height: 50)
    
  }
  
  
}
