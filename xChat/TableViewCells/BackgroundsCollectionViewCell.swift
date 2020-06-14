//
//  BackgroundsCollectionViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 5.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

class BackgroundsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!

    func generateCell(image: UIImage) {
        self.imageView.image = image
    }
}
