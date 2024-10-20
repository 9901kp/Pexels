//
//  ImageScrollViewController.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 3/7/24.
//

import UIKit

class ImageScrollViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    let imageUrl: String
    
    init(imageUrl:String){
        self.imageUrl = imageUrl
        super.init(nibName: "ImageScrollViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self

        loadImage()
        // Do any additional setup after loading the view.
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
    }
    
    
    @objc
    func shareTapped(){
        guard let image = imageView.image?.jpegData(compressionQuality: 0.8) else {
            print("No image found")
            return
        }
        
        let vc  = UIActivityViewController(activityItems: [image], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
    
    

    func loadImage() {
        guard let url = URL(string: imageUrl) else{
            print("Couldn't create url instance with image url: \(imageUrl)")
            return
        }
        
        self.activityIndicatorView.startAnimating()
        let dataTask = URLSession.shared.dataTask(with: url, completionHandler: complationHandler(data:urlResponse:error:))
        dataTask.resume()
    
    }

    func complationHandler(data: Data?, urlResponse: URLResponse?, error: Error?){
        
        DispatchQueue.main.async{
            self.activityIndicatorView.stopAnimating()
        }
        if let error = error{
            print("Image loading error: \(error.localizedDescription)")
        }else if let data = data{
            DispatchQueue.main.async{
                self.imageView.image = UIImage(data: data)
            }
        }
    }

}

extension ImageScrollViewController: UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
