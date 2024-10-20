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
        pages = [OnboardingModel(imageName: "onboarding1", title: "Добро пожаловать в Pexels!", subtitle: "Исследуйте миллионы красивых фотографий под любое слово. Наше приложение помогает вам найти и сохранить вдохновение."),
        OnboardingModel(imageName: "onboarding2", title: "Легкий поиск фотографий", subtitle: "Введите любое слово в поисковую строку и найдите тысячи фотографий по вашей теме. Мы обеспечиваем быстрый и точный поиск."),
        OnboardingModel(imageName: "onboarding3", title: "Сохраняйте и делитесь", subtitle: "Сохраняйте ваши поисковые запросы и добавляйте понравившиеся фотографии в избранное. Легко возвращайтесь к ним в любое время и делитесь с друзьями.")]
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
            nextButton.setTitle("Начать", for: .normal)
        }else{
            skipButton.isHidden = false
            nextButton.setTitle("Дальше", for: .normal)
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
