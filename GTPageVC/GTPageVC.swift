//
//  GTPageVC.swift
//  Gametime
//
//  Created by Adrian on 10/17/16.
//
//

import UIKit
import SnapKit

public protocol GTPageVCDelegate : class {
    func didScroll(toVC vc : UIViewController, index : Int)
}


open class GTPageVC: UIViewController {
    
    open fileprivate(set) var viewControllers = [UIViewController]()
    
    open weak var pageDelegate : GTPageVCDelegate?
    
    fileprivate(set) lazy var collectionView : UICollectionView = { [unowned self] in
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: self.layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(GTPageCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: String(describing: GTPageCollectionViewCell.self))
        return collectionView
    }()
    
    fileprivate var itemSpacing : CGFloat = 8.0
    
    fileprivate lazy var layout : UICollectionViewFlowLayout = { [unowned self] in
        let pageLayout = UICollectionViewFlowLayout()
        pageLayout.scrollDirection = .horizontal
        pageLayout.sectionInset = UIEdgeInsets(top: 0, left: self.itemSpacing / 2.0, bottom: 0, right: self.itemSpacing / 2.0)
        pageLayout.minimumLineSpacing = self.itemSpacing
        return pageLayout
        }()
    
    //MARK: Selection
    
    open func set(viewControllers : [UIViewController], selectedIndex index : Int = 0) {
        guard viewIfLoaded != nil else { return }

        self.viewControllers = viewControllers

        collectionView.reloadData()

        scroll(index: index, animated: false)
    }
    
    open func selectedVC() -> UIViewController? {
        guard let visibleCell = collectionView.visibleCells.first as? GTPageCollectionViewCell else { return nil }
        return visibleCell.containedVC
    }
    
    open func selectedIndex() -> Int? {
        guard let selectedVC = selectedVC() else { return nil }
        return viewControllers.index(of: selectedVC)
    }
    
    open func scroll(index : Int, animated : Bool) {
        guard index < viewControllers.count else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
    }
    
    //MARK: VC Management
    
    fileprivate func addPageChild(fromCell cell : GTPageCollectionViewCell) {
        guard let containedVC = cell.containedVC  else { return }
        cell.contentView.addSubview(containedVC.view)
        containedVC.view.snp.makeConstraints({ (make) in make.edges.equalTo(cell.contentView) })
        addChildViewController(containedVC)
        containedVC.didMove(toParentViewController: self)
    }
    
    fileprivate func removePageChild(fromCell cell : GTPageCollectionViewCell) {
        guard let containedVC = cell.containedVC  else { return }
        containedVC.view.removeFromSuperview()
        containedVC.removeFromParentViewController()
    }
    
    //MARK: Scrolling
    
    fileprivate func didEndScroll() {
        guard let selectedVC = self.selectedVC(), let selectedIndex = self.selectedIndex() else { return }
        pageDelegate?.didScroll(toVC: selectedVC, index: selectedIndex)
    }
    
    //MARK: UIViewController
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layout.invalidateLayout()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard collectionView.superview == nil else { return }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints({ (make) in
            make.edges.equalTo(self.view).inset(UIEdgeInsets(top: 0, left: -self.itemSpacing/2.0, bottom: 0, right: -self.itemSpacing/2.0))
        })
        collectionView.reloadData()
    }
}

extension GTPageVC : UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - self.itemSpacing, height: view.frame.height)
    }
}

extension GTPageVC : UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pageCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GTPageCollectionViewCell.self), for: indexPath) as! GTPageCollectionViewCell
        let vc = viewControllers[indexPath.row]
        pageCell.containedVC = vc
        return pageCell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewControllers.count
    }
    
}

extension GTPageVC : UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.removePageChild(fromCell: cell as! GTPageCollectionViewCell)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.addPageChild(fromCell: cell as! GTPageCollectionViewCell)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndScroll()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        didEndScroll()
    }
}
