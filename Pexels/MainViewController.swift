//
//  MainViewController.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 31/5/24.
//

import UIKit

class LoadingFooterView: UICollectionReusableView {
    static let identifier = "LoadingFooterView"
    let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MainViewController: UIViewController {

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var searchHistoryCollectionView: UICollectionView!
    @IBOutlet var imageCollectionView: UICollectionView!
    
    // MARK: - НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ ПАГИНАЦИИ
    var currentPage = 1
    var isFetchingMore = false
    
    // Теперь это массив, к которому мы сможем добавлять новые фотки
    var photos: [Photo] = [] {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.reloadData()
            }
        }
    }
    
    let savedSearchHistoryArrayKey: String = "savedSearchHistoryArrayKey"
    var searchTextArray: [String] = [] {
        didSet{
            searchHistoryCollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Pexels"
        searchBar.delegate = self
        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        imageCollectionView.register(UINib(nibName: PhotoCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        // Настройка Pull-to-Refresh
        imageCollectionView.refreshControl = UIRefreshControl()
        imageCollectionView.refreshControl?.addTarget(self, action: #selector(search), for: .valueChanged)
        
        // SearchHistory SetUp
        let flowLayout = searchHistoryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        searchHistoryCollectionView.register(UINib(nibName: SearchHistoryCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: SearchHistoryCollectionViewCell.identifier)
        searchHistoryCollectionView.dataSource = self
        searchHistoryCollectionView.delegate = self

        imageCollectionView.register(LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.identifier)
        resetSearchHistory()
    }
    
    
    // MARK: - НОВАЯ ЛОГИКА ЗАГРУЗКИ (Обновление и Пагинация)
    
    @objc func search() {
        // При новом поиске или свайпе вниз сбрасываем всё до 1 страницы
        currentPage = 1
        isFetchingMore = false
        
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            imageCollectionView.refreshControl?.endRefreshing()
            return
        }
        
        save(searchText: searchText)
        fetchPhotos(isRefresh: true)
    }
    
    func loadMorePhotos() {
        // Если уже грузим или текст пустой - отменяем
        guard !isFetchingMore, let searchText = searchBar.text, !searchText.isEmpty else { return }
        isFetchingMore = true

        // Обновляем макет, чтобы появился футер
        DispatchQueue.main.async {
            self.imageCollectionView.collectionViewLayout.invalidateLayout()
        }

        currentPage += 1
        fetchPhotos(isRefresh: false)
    }
    
    
    func fetchPhotos(isRefresh: Bool) {
        guard let searchText = searchBar.text else { return }
        
        if isRefresh {
            if imageCollectionView.refreshControl?.isRefreshing == false {
                imageCollectionView.refreshControl?.beginRefreshing()
            }
        }
        
        let endpoint = "https://api.pexels.com/v1/search"
        guard var urlComponent = URLComponents(string: endpoint) else { return }
        
        // Добавили параметр "page" и изменили "per-page" на "per_page" (как требует Pexels API)
        let parameters = [
            URLQueryItem(name: "query", value: searchText),
            URLQueryItem(name: "per_page", value: "30"), // Грузим по 30 штук за раз
            URLQueryItem(name: "page", value: "\(currentPage)") // Номер страницы
        ]
        urlComponent.queryItems = parameters
        
        guard let url = urlComponent.url else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        let APIKey = "as3X1H4LC7yevkXt2PCKDSWBSMx1k8WZosuH0aEo9PsJM1qxh9ZoPRl6"
        urlRequest.addValue(APIKey, forHTTPHeaderField: "Authorization")
        
        let urlSession = URLSession(configuration: .default)
        let dataTask = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Выключаем крутилки загрузки
            DispatchQueue.main.async {
                if isRefresh {
                    self.imageCollectionView.refreshControl?.endRefreshing()
                }
            }
            
            if let error = error {
                print("Error - \(error.localizedDescription)")
                self.isFetchingMore = false
                return
            }
            
            if let data = data {
                do {
                    let searchPhotosResponse = try JSONDecoder().decode(SearchPhotosResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        if isRefresh {
                            // Если это новый поиск или свайп сверху - перезаписываем массив
                            self.photos = searchPhotosResponse.photos
                        } else {
                            // Если это скролл вниз - добавляем новые фотки к старым
                            self.photos.append(contentsOf: searchPhotosResponse.photos)
                        }
                        self.isFetchingMore = false // Снимаем блок
                    }
                } catch {
                    print("Serialization error - \(error.localizedDescription)")
                    self.isFetchingMore = false
                }
            }
        }
        // Когда данные загружены или произошла ошибка
        self.isFetchingMore = false
        self.imageCollectionView.collectionViewLayout.invalidateLayout() // Футер скроется
        self.imageCollectionView.reloadData()
        
        dataTask.resume()
    }
    
    // MARK: - ИСТОРИЯ ПОИСКА
    
    func save(searchText: String){
        var existingArr: [String] = getSearchTextArr()
        existingArr.append(searchText)
        UserDefaults.standard.set(existingArr, forKey: savedSearchHistoryArrayKey)
        resetSearchHistory()
    }
    
    func getSearchTextArr() -> [String]{
        return UserDefaults.standard.stringArray(forKey: savedSearchHistoryArrayKey) ?? []
    }
    
    @IBAction func clearAllTextHistory(_ sender: UIButton) {
        clearSearchHistory()
    }
    
    func clearSearchHistory() {
        UserDefaults.standard.removeObject(forKey: savedSearchHistoryArrayKey)
        searchTextArray = []
    }
    
    func getSortedSearchArray() -> [String]{
        return getSearchTextArr().reversed()
    }
    
    func resetSearchHistory() {
        self.searchTextArray = getUniqueSearchTextArray()
    }
    
    func getUniqueSearchTextArray() -> [String] {
        let sortedSearchTextArray = getSortedSearchArray()
        var uniqueArr: [String] = []
        sortedSearchTextArray.forEach { searchText in
            if !uniqueArr.contains(searchText) {
                uniqueArr.append(searchText)
            }
        }
        return uniqueArr
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        search()
    }
}

// MARK: - UICollectionViewDataSource
extension MainViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case imageCollectionView:
            return photos.count
        case searchHistoryCollectionView:
            return searchTextArray.count
        default:
            return 0
        }
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView{
        case imageCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
            cell.setUp(photo: self.photos[indexPath.item])
            return cell
            
        case searchHistoryCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchHistoryCollectionViewCell.identifier, for: indexPath) as! SearchHistoryCollectionViewCell
            cell.set(title: searchTextArray[indexPath.item])
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter && collectionView == imageCollectionView {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingFooterView.identifier, for: indexPath) as! LoadingFooterView
            return footer
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout & Delegate
extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            // 1. ИСПРАВЛЕНИЕ: Возвращаем безопасный размер заглушку для истории поиска.
            // Реальная ширина посчитается сама на основе текста внутри ячейки.
            if collectionView == searchHistoryCollectionView {
                return CGSize(width: 100, height: 40)
            }
            
            // 2. Расчет для сетки с картинками
            let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
            let horizontalSpacing = (flowLayout?.minimumInteritemSpacing ?? 0) + collectionView.contentInset.left + collectionView.contentInset.right
            
            // 3. Защита от отрицательной ширины (на всякий случай)
            let safeWidth = max(0, collectionView.frame.width - horizontalSpacing)
            let width = safeWidth / 2
            
        
            return CGSize(width: width, height: width)
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        // Если сейчас идет загрузка и это основная коллекция — показываем футер высотой 50
        if isFetchingMore && collectionView == imageCollectionView {
            return CGSize(width: collectionView.frame.width, height: 50)
        }
        return .zero
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView{
        case imageCollectionView:
            let photo = self.photos[indexPath.item]
            let url = photo.src.large2X
            
            let vc = ImageScrollViewController(imageUrl: url)
            self.navigationController?.pushViewController(vc, animated: true)
        case searchHistoryCollectionView:
            let searchText = searchTextArray[indexPath.item]
            searchBar.text = searchText
            search()
            
        default:
            break
        }
    }
    
    // MARK: - НОВОЕ: Отслеживаем скролл для пагинации
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Проверяем, что это коллекция с картинками, а не история поиска
        if collectionView == imageCollectionView {
            // Если показывается последняя картинка из массива
            if indexPath.item == photos.count - 1 {
                loadMorePhotos()
            }
        }
    }
}
