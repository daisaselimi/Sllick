//
//  PicturesCollectionViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 31.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import IDMPhotoBrowser
import SKPhotoBrowser
import UIKit

class PicturesCollectionViewController: UICollectionViewController {
    
    var allImages: [UIImage] = []
    var allImageLinks: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "All Pictures"
        
        if allImageLinks.count > 0 {
            downloadImages()
        } else {
            collectionView.setEmptyMessage("No shared pictures")
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using [segue destinationViewController].
         // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return allImages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PictureCollectionViewCell
        
        cell.generateCell(image: allImages[indexPath.row])
        
        // Configure the cell
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        let photos = IDMPhoto.photos(withImages: allImages)
//        let browser = IDMPhotoBrowser(photos: photos)
//        browser?.displayDoneButton = false
//        browser?.setInitialPageIndex(UInt(indexPath.row))
//        self.present(browser!, animated: true, completion: nil)
        
        var images = [SKPhoto]()
        
        for photo in allImages {
            let pht = SKPhoto.photoWithImage(photo)
            images.append(pht)
        }
        
        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(indexPath.row)
        present(browser, animated: true, completion: nil)
    }
    
    // MARK: DownloadImages
    
    func downloadImages() {
        for imageLink in allImageLinks {
            downloadImage(imageUrl: imageLink) { image in
                
                if image != nil {
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }
}
