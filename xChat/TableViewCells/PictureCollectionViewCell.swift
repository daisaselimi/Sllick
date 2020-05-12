
//
//  PictureCollectionViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 31.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

class PictureCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        self.imageView.image = image
    }
}



