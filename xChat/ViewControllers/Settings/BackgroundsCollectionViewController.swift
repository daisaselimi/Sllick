//
//  BackgroundsCollectionViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 5.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import ProgressHUD
import UIKit

private let reuseIdentifier = "Cell"

class BackgroundsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var backgrounds: [UIImage] = []
    let userDefaults = UserDefaults.standard
    
    private let imageNamesArray = ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7", "bg8", "bg9", "bg10", "bg11"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetToDefault))
        navigationItem.rightBarButtonItem = resetButton
        setupImageArray()
        navigationItem.largeTitleDisplayMode = .never
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
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgrounds.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BackgroundsCollectionViewCell
        
        cell.generateCell(image: backgrounds[indexPath.row])
        
        // Configure the cell
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userDefaults.set(imageNamesArray[indexPath.row], forKey: kBACKGROUNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess()
    }
    
    func setupImageArray() {
        for imageName in imageNamesArray {
            let image = UIImage(named: imageName)
            
            if image != nil {
                backgrounds.append(image!)
            }
        }
    }
    
    // MARK: IBActions
    
    @objc func resetToDefault() {
        userDefaults.removeObject(forKey: kBACKGROUNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width / 3 - 14, height: 200)
    }
}
