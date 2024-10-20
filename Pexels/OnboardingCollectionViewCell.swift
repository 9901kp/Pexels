//
//  OnboardingCollectionViewCell.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 27/5/24.
//

import UIKit

class OnboardingCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "OnboardingCollectionViewCell"
    
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var innerStackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    func setUp(onboardingModel: OnboardingModel){
        imageView.image = UIImage(named: onboardingModel.imageName)
        titleLabel.text = onboardingModel.title
        subtitleLabel.text = onboardingModel.subtitle
    }
}
