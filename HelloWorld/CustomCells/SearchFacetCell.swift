//
//  SearchFacetsCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/04/27.
//

import UIKit

class SearchFacetCell: UITableViewCell {
    
    static let identifier = "SearchFacetCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var facetedText: UILabel!
    @IBOutlet weak var facetedCounts: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(facet: Facet) {
        facetedText.text = facet.value
        facetedCounts.text = "\(facet.count) channels"
    }
    
}
