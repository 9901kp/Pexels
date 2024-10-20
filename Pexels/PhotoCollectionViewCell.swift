//
//  PhotoCollectionViewCell.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 28/6/24.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    static let identifier: String = "PhotoCollectionViewCell"
    var photo: Photo?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageView.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {//Для того чтобы подготовить ячейку к переиспользованию
        super.prepareForReuse()
        self.imageView.image = UIImage(named: "placeholder")
    }

    func setUp(photo: Photo){
        self.photo = photo
        let mediumPhotoUrlString = photo.src.medium
        guard let mediumPhotoURL = URL(string: mediumPhotoUrlString) else {
            print("couldn't create url with this given mediumPhotoUrlString - \(mediumPhotoUrlString)")
            return
        }
        
        self.activityIndicatorView.startAnimating()
        let dataTask = URLSession.shared.dataTask(with: mediumPhotoURL, completionHandler: imageLoadComplationHandler(data:urlResponse:error:))
        dataTask.resume()
    }
    func imageLoadComplationHandler(data: Data?, urlResponse: URLResponse?, error: Error?){
        if urlsAreSame(responseURL: urlResponse?.url?.absoluteString){
            DispatchQueue.main.async{
                self.activityIndicatorView.stopAnimating()
            }
        }
        
        if let error = error  {
            print("Error loading image")
        }else if let data = data {
            guard urlsAreSame(responseURL: urlResponse?.url?.absoluteString) else{
                return
            }
           
            DispatchQueue.main.async{
                self.imageView.image = UIImage(data: data)
            }
        }
    }
    
    func urlsAreSame(responseURL: String?) -> Bool{
        guard let currentPhotoUrl = self.photo?.src.medium, let responseUrl = responseURL else {
            print("Current photo url OR response url are absent")
            return false
        }
        
        guard currentPhotoUrl == responseUrl else{
            print("Attention? CurrentPhotoUrl and responseUrl are different")
            return false
        }
        return true
    }
}
