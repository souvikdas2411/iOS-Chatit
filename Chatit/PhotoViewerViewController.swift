//
//  PhotoViewerViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {

    @IBOutlet var imageView : UIImageView!
    
    public var imageUrl = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
    }
    


}
