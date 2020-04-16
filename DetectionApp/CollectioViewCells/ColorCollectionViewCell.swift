//
//  ColorCollectionViewCell.swift
//  DetectionApp
//
//  Created by Anton Bal’ on 9/19/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

import UIKit

final class ColorCollectionViewCell: UICollectionViewCell {
    
    //MARK: - @IBOutlet's
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var colorView: UIView!
    
    //MARK: - Properies
    
    private lazy var borderLayer: CALayer = {
        let borderLayer = CALayer()
        borderLayer.frame = bounds
        borderLayer.borderWidth = 2
        borderLayer.cornerRadius = bounds.width / 2
        layer.addSublayer(borderLayer)
        return borderLayer
    }()
    
    var color: UIColor? {
        set {
            colorView.backgroundColor = newValue
            layoutIfNeeded()
        }
        get { return colorView.backgroundColor }
    }
    
    override var isSelected: Bool {
        didSet {
            imageView.image = isSelected ? UIImage(named: "icCheckmark") : nil
            borderLayer.borderColor = isSelected ? colorView.backgroundColor?.cgColor : nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorView.layer.cornerRadius = colorView.bounds.width / 2
    }
}
