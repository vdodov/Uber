//
//  HomeController.swift
//  Uber
//
//  Created by 차수연 on 2020/04/28.
//  Copyright © 2020 차수연. All rights reserved.
//

import UIKit
import Firebase
import MapKit

private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfiguration {
  case showMenu
  case dimissActionView
  
  init() {
    self = .showMenu
  }
}


class HomeController: UIViewController {
  
  // MARK: - Properties
  
  private let mapView = MKMapView()
  private let locationManager = LocationHandler.shared.locationManager
  
  private let inputActivationView = LocationInputActionView()
  private let rideActionView = RideActionView()
  private let locationInputView = LocationInputView()
  private let tableView = UITableView()
  private var searchResults = [MKPlacemark]()
  
  private final let locationInputViewHeight: CGFloat = 200
  private final let rideActionViewHeight: CGFloat = 300
  
  private var actionButtonConfig = ActionButtonConfiguration()
  
  private var route: MKRoute?
  
  private var user: User? {
    didSet {
      locationInputView.user = user
      
      if user?.accountType == .passenger {
        fetchDrivers()
        configureLoactionInputActivationView()
        observeCurrentTrip()
      } else {
        observeTrips()
      }
    }
  }
  
  private var trip: Trip? {
    didSet {
      guard let user = user else { return }
      
      if user.accountType == .driver {
        guard let trip = trip else { return }
        let controller = PickupController(trip: trip)
        controller.modalPresentationStyle = .fullScreen
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
      } else {
        print("DEBUG: Show ride action view for accepted trip..")
      }
    }
  }
  
  private let actionButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
    button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
    return button
  }()
  
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    checkIfUserIsLoggedIn()
    enableLocationServices()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    guard let trip = trip else { return }
    print("DEBUG: Trip state is \(trip.state)")
    
  }
  
  // MARK: - Selectors
  
  @objc func actionButtonPressed() {
    switch actionButtonConfig {
    case .showMenu:
      print("DEBUG: Handle show menu..")
    case .dimissActionView:
      print("DEBUG: Handle dismissal..")
      removeAnnotationsAndOverlays()
      mapView.showAnnotations(mapView.annotations, animated: true)
      
      UIView.animate(withDuration: 0.3) {
        self.inputActivationView.alpha = 1
        self.configureActionButton(config: .showMenu)
        self.animateRideActionView(shouldShow: false)
      }
    }
  }
  
  // MARK: - API
  
  func observeCurrentTrip() {
    Service.shared.observeCurrentTrip { (trip) in
      self.trip = trip
      
      if trip.state == .accepted {
        self.shouldPresentLoadingView(false)
        
        guard let driverUid = trip.driverUid else { return }
        Service.shared.fetchUserData(uid: driverUid) { driver in
          self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
        }
      
      }
    }
  }
  
  func fetchUserData() {
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    Service.shared.fetchUserData(uid: currentUid) { user in
      self.user = user
    }
  }
  
  func fetchDrivers() {
    guard let location = locationManager?.location else { return }
    Service.shared.fetchDrivers(location: location) { (driver) in
      guard let coordinate = driver.location?.coordinate else { return }
      let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
      print("DEBUG: Driver Coordinate is \(coordinate)")
      
      var driverIsVisible: Bool {
        return self.mapView.annotations.contains(where: { annotation -> Bool in
          guard let driverAnno = annotation as? DriverAnnotation else { return false }
          if driverAnno.uid == driver.uid {
            driverAnno.updateAnnotationPostion(withCoordinate: coordinate)
            
            return true
          }
          return false
        })
      }
      
      if !driverIsVisible {
        self.mapView.addAnnotation(annotation)
      }
    }
  }
  
  func observeTrips() {
    Service.shared.observeTrips { trip in
      self.trip = trip
    }
  }
  
  func checkIfUserIsLoggedIn() {
    if Auth.auth().currentUser?.uid == nil { //사용자가 로그인 되어있지 않을때..
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } else {
      configure()
    }
  }
  
  func signOut() {
    do {
      try Auth.auth().signOut()
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } catch {
      print("DEBUG: Error signing out")
    }
  }
  
  // MARK: - Helper Functions
  
  func configure() {
    configureUI()
    fetchUserData()
  }
  
  fileprivate func configureActionButton(config: ActionButtonConfiguration) {
    switch config {
    case .showMenu:
      self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
      self.actionButtonConfig = .showMenu
    case .dimissActionView:
      actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
      actionButtonConfig = .dimissActionView
      
    }
  }
  
  func configureUI() {
    configureMapView()
    configureRideActionView()
    
    view.addSubview(actionButton)
    actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                        paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
    
    configureTableView()
  }
  
  func configureLoactionInputActivationView() {
    
    view.addSubview(inputActivationView)
    inputActivationView.centerX(inView: view)
    inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
    inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
    inputActivationView.alpha = 0
    inputActivationView.delegate = self
    
    UIView.animate(withDuration: 2) {
      self.inputActivationView.alpha = 1
    }
    
  }
  
  func configureMapView() {
    view.addSubview(mapView)
    mapView.frame = view.frame
    
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .follow
    
    mapView.delegate = self
  }
  
  func configureLocationInputView() {
    locationInputView.delegate = self
    
    view.addSubview(locationInputView)
    locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
    locationInputView.alpha = 0
    
    UIView.animate(withDuration: 0.5, animations: {
      self.locationInputView.alpha = 1
    }) { _ in
      UIView.animate(withDuration: 0.3) {
        self.tableView.frame.origin.y = self.locationInputViewHeight
      }
    }
  }
  
  func configureRideActionView() {
    view.addSubview(rideActionView)
    rideActionView.delegate = self
    rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    
  }
  
  func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    
    tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
    tableView.rowHeight = 60
    tableView.tableFooterView = UIView()
    
    let height = view.frame.height - locationInputViewHeight
    tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
    
    view.addSubview(tableView)
    
  }
  
  func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
    
    UIView.animate(withDuration: 0.3, animations: {
      self.locationInputView.alpha = 0
      self.tableView.frame.origin.y = self.view.frame.height
      self.locationInputView.removeFromSuperview()
    }, completion: completion)
  }
  
  func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil,
                             config: RideActionViewConfiguration? = nil, user: User? = nil) {
    let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
    
    UIView.animate(withDuration: 0.3) {
      self.rideActionView.frame.origin.y = yOrigin
    }
    
    if shouldShow {
      guard let config = config else { return }
      rideActionView.configureUI(withConfig: config)
      
      if let destination = destination {
        rideActionView.destination = destination
      }
      
      if let user = user {
        rideActionView.user = user
      }
      
    }
    
  }
  
}

// MARK: - MapView Helper Functions
private extension HomeController {
  func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
    var results = [MKPlacemark]()
    
    let request = MKLocalSearch.Request()
    request.region = mapView.region
    request.naturalLanguageQuery = naturalLanguageQuery
    
    let search = MKLocalSearch(request: request)
    search.start { (response, error) in
      guard let response = response else { return }
      
      response.mapItems.forEach { item in
        results.append(item.placemark)
      }
      
      completion(results)
    }
  }
  
  func generatePolyline(toDestination destination: MKMapItem) {
    
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = destination
    request.transportType = .automobile
    
    let directionRequest = MKDirections(request: request)
    directionRequest.calculate { (response, error) in
      guard let response = response else { return }
      self.route = response.routes[0]
      guard let polyline = self.route?.polyline else { return }
      self.mapView.addOverlay(polyline)
    }
  }
  
  func removeAnnotationsAndOverlays() {
    mapView.annotations.forEach { (annotation) in
      if let anno = annotation as? MKPointAnnotation {
        mapView.removeAnnotation(anno)
      }
    }
    
    if mapView.overlays.count > 0 {
      mapView.removeOverlay(mapView.overlays[0])
    }
  }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? DriverAnnotation {
      let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
      view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
      return view
    }
    return nil
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let route = self.route {
      let polyline = route.polyline
      let lineRenderer = MKPolylineRenderer(overlay: polyline)
      lineRenderer.strokeColor = .mainBlueTint
      lineRenderer.lineWidth = 4
      return lineRenderer
    }
    return MKOverlayRenderer()
  }
  
}

// MARK: - LocationServices

extension HomeController {
  func enableLocationServices() {
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      print("DEBUG: Not determined..")
      locationManager?.requestWhenInUseAuthorization()
    case .restricted, .denied:
      break
    case .authorizedAlways:
      print("DEBUG: Auth always..")
      locationManager?.startUpdatingLocation()
      locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    case .authorizedWhenInUse:
      print("DEBUG: Auth when in use..")
      locationManager?.requestAlwaysAuthorization()
    @unknown default:
      break
    }
  }
  
  
}

// MARK: - LocationInputActionViewDelegate

extension HomeController: LocationInputActionViewDelegate {
  func presentLocationInputView() {
    inputActivationView.alpha = 0
    configureLocationInputView()
  }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
  func executeSearch(query: String) {
    searchBy(naturalLanguageQuery: query) { (results) in
      self.searchResults = results
      self.tableView.reloadData()
    }
  }
  
  func dismissLocationInputView() {
    dismissLocationView { _ in
      UIView.animate(withDuration: 0.5) {
        self.inputActivationView.alpha = 1
      }
    }
  }
  
}

// MARK: - UITableViewDelegate/DataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "Test"
  }
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? 2 : searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.identifier, for: indexPath) as! LocationCell
    if indexPath.section == 1 {
      cell.placemark = searchResults[indexPath.row]
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedPlacemark = searchResults[indexPath.row]
    
    configureActionButton(config: .dimissActionView)
    
    let destination = MKMapItem(placemark: selectedPlacemark)
    generatePolyline(toDestination: destination)
    
    dismissLocationView { _ in
      let annotation = MKPointAnnotation()
      annotation.coordinate = selectedPlacemark.coordinate
      self.mapView.addAnnotation(annotation)
      self.mapView.selectAnnotation(annotation, animated: true)
      
      let annotations = self.mapView.annotations.filter {( !$0.isKind(of: DriverAnnotation.self) )}
      self.mapView.zoomToFit(annotations: annotations)
      
      self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
      
    }
    
  }
  
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
  func uploadTrip(_ view: RideActionView) {
    guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
    guard let destinationCoordinates = view.destination?.location?.coordinate else { return }
    
    shouldPresentLoadingView(true, message: "Finding you a ride..")
    
    Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (err, ref) in
      if let error = err {
        print("DEBUG: Failed to upload trip with error \(error)")
        return
      }
      print("DEBUG Did upload trip successfully")
      UIView.animate(withDuration: 0.3, animations: {
        self.rideActionView.frame.origin.y = self.view.frame.height
      })
    }
  }
  
  
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
  func didAcceptTrip(_ trip: Trip) {
    self.trip?.state = .accepted
    
    let anno = MKPointAnnotation()
    anno.coordinate = trip.pickupCoordinates
    mapView.addAnnotation(anno)
    
    let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
    let mapItem = MKMapItem(placemark: placemark)
    generatePolyline(toDestination: mapItem)
    
    mapView.zoomToFit(annotations: mapView.annotations)
    
    
    self.dismiss(animated: true) {
      Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
        self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
      }
    }
  }
}
