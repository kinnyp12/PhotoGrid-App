//
//  ViewController.swift
//  PhotoGrid App
//
//  Created by Kinny Padia on 15/04/24.
//

import UIKit

class ViewController: UIViewController {
    
//    private let unsplashService = UnsplashService()
    private var photos: [UnsplashPhoto] = []
    var currentPage = 1
    
    @IBOutlet weak var cvLoadImages: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
//        fetchPhotos()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        cvLoadImages.collectionViewLayout = layout

        fetchUnsplashPhotos(completion: nil)
    }
    
    private func loadMorePhotos() {
        loadMore { [weak self] newPhotos in
            DispatchQueue.main.async {
                if let newPhotos = newPhotos {
                    self?.cvLoadImages.reloadData()
                }
            }
        }
    }

    func loadMore(completion: @escaping ([UnsplashPhoto]?) -> Void) {
        currentPage += 1
        fetchUnsplashPhotos(completion: completion)
    }

    func fetchUnsplashPhotos(completion: (([UnsplashPhoto]?) -> Void)? = nil) {
        let accessKey = "aDgITxdznI2smzG0nvCvIY7uZvFu2HSmJNZgpnF7v9M"
        let urlString = "https://api.unsplash.com/photos/?client_id=\(accessKey)&page=\(currentPage)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                // Parse JSON response
                let decoder = JSONDecoder()
                let unsplashPhotos = try decoder.decode([UnsplashPhoto].self, from: data)
                
                // Update the photos array on the main queue
                DispatchQueue.main.async {
                    self?.photos += unsplashPhotos
                    self?.cvLoadImages.reloadData()
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! MyCollectionViewCell
                
        let url = photos[indexPath.item]
        cell.configure(with: url)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = 5
        let collectionViewSize = collectionView.frame.size.width - padding * 4
        let itemWidth = collectionViewSize / 3
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == photos.count - 1 {
            loadMorePhotos()
        }
    }

}

class MyCollectionViewCell: UICollectionViewCell{
    
    @IBOutlet weak var imgDisplay: UIImageView!
    
    func configure(with photo: UnsplashPhoto) {
        // Load image asynchronously
        if let url = URL(string: photo.urls.raw) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    self.imgDisplay.image = UIImage(data: data)
                }
            }.resume()
        }
    }
}

struct UnsplashPhoto: Decodable {
    let urls: PhotoURLs
}

struct PhotoURLs: Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
    let small_s3: String
}
