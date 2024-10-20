//
//  SearchHistoryCollectionViewCell.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 5/7/24.
//

import UIKit

class SearchHistoryCollectionViewCell: UICollectionViewCell {

    static let identifier: String =  "SearchHistoryCollectionViewCell"
    @IBOutlet var cardView: UIView!
    @IBOutlet var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.lightGray.cgColor
        cardView.layer.cornerRadius = 10
    }

    func set(title: String){
        titleLabel.text = title
    }
    
}
