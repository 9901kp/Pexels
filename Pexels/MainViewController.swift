//
//  MainViewController.swift
//  Pexels
//
//  Created by Мухаммед Каипов on 31/5/24.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var searchHistoryCollectionView: UICollectionView!
    @IBOutlet var imageCollectionView: UICollectionView!
    
    var searchPhotosResponse: SearchPhotosResponse?{
        didSet{
            DispatchQueue.main.async {
                self.imageCollectionView.reloadData()
            }
        }
    }
    var photos: [Photo]{
        return searchPhotosResponse?.photos ?? []
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
        imageCollectionView.refreshControl = UIRefreshControl()
        imageCollectionView.refreshControl?.addTarget(self, action: #selector(search), for: .valueChanged)
        
        //SearchHistory SetUp
        let flowLayout = searchHistoryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        searchHistoryCollectionView.register(UINib(nibName: SearchHistoryCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: SearchHistoryCollectionViewCell.identifier)
        searchHistoryCollectionView.dataSource = self
        // Обращаемся к свойству 'delegate' у 'searchHistoryCollectionView' и присваеваем обьект текущего класса, а именно экземпляр класса MainViewController. Иными словами, перенимаем ответственность, которая находится в протоколе UICollectionViewDelegate. Делается это с целью получения обратной связи, в нашем случае для обнаружения выбора ячейки.
        searchHistoryCollectionView.delegate = self

        // Теперь для переопределения значения свойства 'searchTextArray' вызываем метод resetSearchTextArray
        resetSearchHistory()
    }
    
    
    @objc
    func search(){
        self.searchPhotosResponse = nil
        
        guard let searchText = searchBar.text else{
            print("Search Bar text is nil")
            return
        }
        guard !searchText.isEmpty else{
            print("Search bar text is empty")
            return
        }
        
        //Save Searching text
        
        save(searchText: searchText)
        
        
        let endpoint: String = "https://api.pexels.com/v1/search"
        guard var urlComponent = URLComponents(string: endpoint) else{
            print("Couldn't create URLComponents instance from endpoint - \(endpoint)")
            return
        }
        
        //Создать и вложить параметры для поиска изображения
        let parameters = [
            URLQueryItem(name: "query", value: searchText),
            URLQueryItem(name: "per-page", value: "80")
        ]
        urlComponent.queryItems = parameters
        
        guard let url: URL = urlComponent.url else{
            print("URL is nil")
            return
        }
        
        
        var urlRequest: URLRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        //MARK: - Код для использование другие http методы (POST,DELETE итд)
        //        urlRequest.httpMethod = "GET"
//        let parameters: [String: Any] = [
//            "query": searchText,
//            "per-page": "10"
//        ]
//        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        
        let APIKey: String = "as3X1H4LC7yevkXt2PCKDSWBSMx1k8WZosuH0aEo9PsJM1qxh9ZoPRl6"
        urlRequest.addValue(APIKey, forHTTPHeaderField: "Authorization")
        
        if imageCollectionView.refreshControl?.isRefreshing == false{
            imageCollectionView.refreshControl?.beginRefreshing()
        }
        
        let urlSession: URLSession = URLSession(configuration: .default)
        let dataTask: URLSessionDataTask = urlSession.dataTask(with: urlRequest, completionHandler: searchPhotosHandler(data:urlResponse:error:))
        
        dataTask.resume()
        
    }
    func searchPhotosHandler(data: Data?,urlResponse: URLResponse?, error: Error?){
        print("Method searchPhotosHandler was called")
        
        DispatchQueue.main.async{
            if self.imageCollectionView.refreshControl?.isRefreshing == true {
                self.imageCollectionView.refreshControl?.endRefreshing()
            }
        }
        
        
        
        if let error = error {
            print("Search photos endpoint error - \(error.localizedDescription)")
        }else if let data = data{
            do{
//                let jsonObject = try JSONSerialization.jsonObject(with: data)
//                print("Search photos endpoint jsonObject - \(jsonObject)")
                    
                let searchPhotosResponse = try JSONDecoder().decode(SearchPhotosResponse.self,from: data)
                print("Search photos endpoint response - \(searchPhotosResponse)")
                self.searchPhotosResponse = searchPhotosResponse
            }catch let error{
                print("Search photos endpoint serialization error - \(error.localizedDescription)")
            }
        }
        
        if let urlResponse = urlResponse, let httpResponse = urlResponse as? HTTPURLResponse{
            print("Search photos endpoint http respons - \(httpResponse.statusCode)")
        }
        
    }
    
    func save(searchText: String){
        var existingArr: [String] = getSearchTextArr()
        existingArr.append(searchText)
        UserDefaults.standard.set(existingArr, forKey: savedSearchHistoryArrayKey)
        
        resetSearchHistory()
    }
    
    func getSearchTextArr() -> [String]{
        let array: [String] = UserDefaults.standard.stringArray(forKey: savedSearchHistoryArrayKey) ?? []
        return array
    }
    
    @IBAction func clearAllTextHistory(_ sender: UIButton) {
        clearSearchHistory()
    }
    
    func clearSearchHistory() {
        UserDefaults.standard.removeObject(forKey: savedSearchHistoryArrayKey)
        searchTextArray = []
    }
    
    func getSortedSearchArray() -> [String]{
        let  savedSearchHistoryArr:[String] = getSearchTextArr()
        let  reversedArray: [String] = savedSearchHistoryArr.reversed()
        return reversedArray
    }
    
    // Новый метод, который переопределеяет значение свойства 'searchTextArray' путем присваения полученного значения метода getSortedSearchTextArray()
    func resetSearchHistory() {
        // Теперь вместо значения метода getSortedSearchTextArray() присваевается значение другого метода getUniqueSearchTextArray()
        self.searchTextArray = getUniqueSearchTextArray()
    }
    func getUniqueSearchTextArray() -> [String] {
        
        // Создается константа и устанавливается начальное значение, где присваевается возвращаемое значение методом getSortedSearchTextArray()
        let sortedSearchTextArray: [String] = getSortedSearchArray()
        
        // Создается пустая переменная для хранения уникальных текстовых запросов
        var sortedSearchTextArrayWithUniqueValues: [String] = []
        
        // Идет итерация по каждомоу элементу массива 'sortedSearchTextArray'
        sortedSearchTextArray.forEach { searchText in
            
            // Идет проверка на отсутствия элемента в массиве 'sortedSearchTextArrayWithUniqueValues'
            // Метод 'contains' возвращает TRUE если 'searchText' уже содержится в массиве 'sortedSearchTextArrayWithUniqueValues'
            if !sortedSearchTextArrayWithUniqueValues.contains(searchText) {
                sortedSearchTextArrayWithUniqueValues.append(searchText)
            }
        }
        // Возвращает массив с уникальныеми текстами
        return sortedSearchTextArrayWithUniqueValues
    }


}



extension MainViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true //Кнопка "Отменить" должна отображатся после начала редактирование текста

    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // Чтобы клавиатура скрылся после нажатии на кнопку Отменить
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false // Кнопка Отменить должен скрываться после окончании редактировании текста
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() //Клавиатура должна скрываться после нажатии на кнопку search
        search()
    }
}







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
}

extension MainViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let flowLayout: UICollectionViewFlowLayout? = collectionViewLayout as? UICollectionViewFlowLayout
        let horizontalSpacing: CGFloat = (flowLayout?.minimumInteritemSpacing ?? 0) + collectionView.contentInset.left + collectionView.contentInset.right
        let width: CGFloat = ( collectionView.frame.width - horizontalSpacing ) / 2
        let height: CGFloat = width
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Теперь отделяем обработку выбора ячейки для соответвующего обьекта UICollectionView, а именно параметра 'collectionView'
        switch collectionView{
        case imageCollectionView:
            let photo = self.photos[indexPath.item]
            let url = photo.src.large2X
            
            let vc = ImageScrollViewController(imageUrl: url)
            self.navigationController?.pushViewController(vc, animated: true)
        case searchHistoryCollectionView:
            // Извлекаем текст из массива 'searchTextArray' c соответсвтующим индексом
            let searchText: String = searchTextArray[indexPath.item]
            // Для свойства 'text' у 'searchBar' присваеваем ранее извлеченный текст
            searchBar.text = searchText
            // Вызываем метод search(), который отправляет запрос для поиска изображений по тексту в поисковой панели
            search()
            
        default:
            ()
        }
    }
}
