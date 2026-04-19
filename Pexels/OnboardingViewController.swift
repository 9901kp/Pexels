//
//  OnboardingViewController.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 27/5/24.
//

import UIKit

class OnboardingViewController: UIViewController {

    static let KEY: String = "UserDidSeeOnboarding"
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var pageControll: UIPageControl!
    
    var pages: [OnboardingModel] = []{
        didSet{
            pageControll.numberOfPages = pages.count
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UINib(nibName: OnboardingCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: OnboardingCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        generatePages()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skipButton.layer.cornerRadius = skipButton.frame.height / 2
        nextButton.layer.cornerRadius = nextButton.frame.height / 2
    }
    
    func generatePages(){
        pages = [
            OnboardingModel(
                imageName: "onboarding1",
                title: "Welcome to Pexels!",
                subtitle: "Explore millions of beautiful photos for any keyword. Our app helps you discover and save inspiration."
            ),
            
            OnboardingModel(
                imageName: "onboarding2",
                title: "Easy Photo Search",
                subtitle: "Enter any keyword in the search bar and find thousands of photos related to your topic. We provide fast and accurate search."
            ),
            
            OnboardingModel(
                imageName: "onboarding3",
                title: "Save and Share",
                subtitle: "Save your searches and add your favorite photos to bookmarks. Easily return to them anytime and share with friends."
            )
        ]
    }
    @IBAction func skipButtonClicked(_ sender: UIButton) {
        start()
    }
    @IBAction func nextButtonClicked(_ sender: UIButton) {
        if pageControll.currentPage == pageControll.numberOfPages - 1{
            start()
        }else{
            pageControll.currentPage += 1
            collectionView.scrollToItem(at: IndexPath(item: pageControll.currentPage, section: 0), at: .centeredHorizontally, animated: true)
            
//            let x: CGFloat = collectionView.frame.width * CGFloat(pageControll.currentPage)
//            collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            handlePageChanges()
        }
    }
    func start(){
        UserDefaults.standard.set(true, forKey: OnboardingViewController.KEY)
        
        let mainVc = MainViewController()
        let navVc = UINavigationController(rootViewController: mainVc)
        view.window?.rootViewController = navVc
        view.window?.makeKeyAndVisible()
    }
    func handlePageChanges(){
        if pageControll.currentPage == pageControll.numberOfPages - 1{
            skipButton.isHidden = true
            nextButton.setTitle("Start", for: .normal)
        }else{
            skipButton.isHidden = false
            nextButton.setTitle("Next", for: .normal)
        }
    }
}


extension OnboardingViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingCollectionViewCell.identifier, for: indexPath) as! OnboardingCollectionViewCell
        
        let onboardingModel = pages[indexPath.item]
        cell.setUp(onboardingModel: onboardingModel)
        
        return cell
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension OnboardingViewController: UIScrollViewDelegate{
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("scrollViewDidEndDecelerating at offset x: \(scrollView.contentOffset.x)")
        print("scrollView.frame.width: \(scrollView.frame.width)")
        
        pageControll.currentPage = Int( scrollView.contentOffset.x / scrollView.frame.width)
        print("pageControll.currentPage: \(pageControll.currentPage)")
        
        handlePageChanges()
    }
}
