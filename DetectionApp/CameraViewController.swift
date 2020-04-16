//
//  CameraViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 3/19/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
   
    //MARK: - Properies
    
    private let ColorCellViewIdentifier = "ColorCellViewIdentifier"
    private let colors = [nil ,#colorLiteral(red: 0.9490196078, green: 0.1254901961, blue: 0.1254901961, alpha: 1),#colorLiteral(red: 0.9803921569, green: 0.3921568627, blue: 0, alpha: 1),#colorLiteral(red: 0.968627451, green: 0.7098039216, blue: 0, alpha: 1),#colorLiteral(red: 0.4274509804, green: 0.831372549, blue: 0, alpha: 1),#colorLiteral(red: 0.2666666667, green: 0.8431372549, blue: 0.7137254902, alpha: 1),#colorLiteral(red: 0.1960784314, green: 0.7725490196, blue: 1, alpha: 1),#colorLiteral(red: 0, green: 0.568627451, blue: 1, alpha: 1),#colorLiteral(red: 0.5759999752, green: 0.1140000001, blue: 0.4040000141, alpha: 1),#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)]
    private lazy var detecor = OpenCVDetector(cameraView: cameraView, scale: 1, preset: .vga640x480, type: .back)
    
    //MARK: - @IBOutlet's
    
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var palletButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var settingsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hValueLabel: UILabel!
    @IBOutlet weak var sValueLabel: UILabel!
    @IBOutlet weak var vValueLabel: UILabel!
    @IBOutlet weak var offsetValueLabel: UILabel!

    @IBOutlet weak var hValueSlider: UISlider!
    @IBOutlet weak var sValueSlider: UISlider!
    @IBOutlet weak var vValueSlider: UISlider!
    @IBOutlet weak var offsetValueSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    //MARK: - Private
    
    private func setup() {
        
        detecor.startCapture()
        
        collectionView.register(UINib(nibName: "ColorCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: ColorCellViewIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        
        //UIGestureRecognizer
        let gesure = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.gestureAction(_:)))
        gesure.delegate = self
        cameraView.addGestureRecognizer(gesure)
        
        hValueSlider.value = 2
        sValueSlider.value = 32
        vValueSlider.value = 32
        offsetValueLabel.text = "0.00"
        
        hsvDidChanged()
    }
    
    private func hsvDidChanged() {
        hValueLabel.text = String(format: "%.2f", hValueSlider.value)
        sValueLabel.text = String(format: "%.2f", sValueSlider.value)
        vValueLabel.text = String(format: "%.2f", vValueSlider.value)
        detecor.setHSVRangeValueWithHValue(hValueSlider.value,
                                           sValue: sValueSlider.value,
                                           vValue: vValueSlider.value)
    }
    
    private func showHideSettings() {
    
        if settingsButton.isSelected {
            settingsBottomConstraint.constant = 0
        } else {
            settingsBottomConstraint.constant = -200
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func gestureAction(_ gesture: UITapGestureRecognizer) {
        var location = gesture.location(in: view)
        
        let width: CGFloat = 480
        let height: CGFloat = 640
        
        let viewWidth = view.frame.width
        var viewHeight = view.frame.height
        viewHeight -= viewHeight - height //becaouse video not in full screen
        
        location.x = round((location.x * width) / viewWidth)
        location.y = round((location.y * height) / viewHeight)
        
        detecor.setDetecting(location)
    }
    
    //MARK: Actions
    
    @IBAction func palletButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        settingsButton.isSelected = !sender.isSelected
        showHideSettings()
    }
    
    @IBAction func settingsButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        palletButton.isSelected = !sender.isSelected
        showHideSettings()
    }
    
    @IBAction func sliderValueAction(_ sender: UISlider) {
        hsvDidChanged()
    }
    
    @IBAction func sliderOffsetAction(_ sender: UISlider) {
        offsetValueLabel.text = String(format: "%.2f", sender.value)
        detecor.setOffset(sender.value)
    }
}

//MARK: - UIGestureRecognizerDelegate

extension CameraViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !collectionView.frame.contains(touch.location(in: view))
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension CameraViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rect = collectionView.bounds.insetBy(dx: 15, dy: 15)
        return CGSize(width: rect.height, height: rect.height)
    }
}

//MARK: - UICollectionViewDelegate

extension CameraViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let selectedItems = collectionView.indexPathsForSelectedItems?.filter({ $0.section == indexPath.section && $0.row != indexPath.row }) {
            selectedItems.forEach { collectionView.deselectItem(at: $0, animated: false) }
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        if colors[indexPath.row]?.getRed(&red, green: &green, blue: &blue, alpha: nil) == true {
            detecor.setFillingColorWithRed(Double(red * 255), green: Double(green * 255), blue: Double(blue * 255))
        } else {
            detecor.resetFillingColor()
        }
    }
}

//MARK: - UICollectionViewDataSource

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCellViewIdentifier, for: indexPath)
        (cell as? ColorCollectionViewCell)?.color = colors[indexPath.row]
        return cell
    }
}
