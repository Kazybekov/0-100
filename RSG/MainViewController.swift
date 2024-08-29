//
//  ViewController.swift
//  RSG
//
//  Created by Yersin Kazybekov on 21.08.2024.
//
import UIKit
import CoreLocation
import CoreMotion

enum appState {
    case start
    case race
    case finish
}

final class MainViewController: UIViewController {
    private var state: appState = .start {
        didSet{
            
            switch state {
            case .start: 
                setLabelsForStart()
            case .race: break
            
            case .finish:
                timeLabel.isHidden = false
                handleFinish()
            }
        }
    }
    
    private let motionManager = CMMotionManager()
    private var startTime: Date?
    private var finishTime: Date?
    private var currentSpeed: Double = 0.0 {
        didSet {
            updateSpeedLabel(newValue: currentSpeed)
            if currentSpeed > 60.0 {
                finishTime = Date()
                state = .finish
            }
        }
    }
    
    let startButton: UIButton = {
        let button = UIButton(type: .custom)
        var image = UIImage(systemName: "flag.2.crossed.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        image = image?.resize(160, 160)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startMeasure), for: .touchUpInside)
        return button
    }()
    
    let speedLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0 km/h"
        label.font = UIFont(name: "Arial", size: 70)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Arial", size: 50)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Arial", size: 50)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
    }
    
    @objc func startMeasure() {
        setupMotionManager()
        setLabelsForRace()
        timeLabel.isHidden = true
    }
    
    private func updateSpeedLabel( newValue: Double) {
        speedLabel.text = "\(newValue.rounded()) km/h"
    }
    
    private func handleFinish() {
        guard let finishTime, let startTime else { return } // show wrong notification
        let differenceInSeconds = finishTime.timeIntervalSince(startTime)
        timeLabel.text = "\(String(format: "%.2g", differenceInSeconds)) seconds"
        motionManager.stopAccelerometerUpdates()
        resetVariables()
        state = .start
    }
    
    private func resetVariables() {
        startTime = nil
        finishTime = nil
        currentSpeed = 0.0
    }
    
    private func setLabelsForRace() {
        startButton.isHidden = true
        infoLabel.isHidden = false
        infoLabel.text = "Start when ready"
    }
    
    private func setLabelsForStart() {
        startButton.isHidden = false
        infoLabel.isHidden = true
        updateSpeedLabel(newValue: 0.0)
    }
    
    private func setupMotionManager() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.01 // 10 Hz
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let data = data {
                    let x = data.acceleration.x
                    let y = data.acceleration.y
                    let acc = sqrt( x * x + y * y )
                    switch self.state {
                    case .start:
                        if acc > 0.1 {
                            self.state = .race
                            self.currentSpeed = self.currentSpeed + acc * 0.01 * 3.6
                            self.startTime = Date()
                        }
                    case .race:
                        self.currentSpeed = self.currentSpeed + acc * 0.01 * 3.6
                    case .finish:
                        self.motionManager.stopAccelerometerUpdates()
                    }
                }
            }
        } else {
            print("handle error")
        }
    }
}

extension MainViewController {
    func setLayout() {
        self.view.backgroundColor = .black

        self.view.addSubview(startButton)
        self.view.addSubview(speedLabel)
        self.view.addSubview(timeLabel)
        self.view.addSubview(infoLabel)
        
        infoLabel.isHidden = true
        timeLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            speedLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200),
            speedLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100),
        ])
        
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 200),
        ])
        
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100),
        ])
    }
}

