//
//  HomeViewController.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/2.
//

import UIKit
import Photos

enum ZSEffectType_Speed {
  case none
  case constant
  case curve
}

final class HomeViewController: UIViewController {
  
  private lazy var renderView = MetalTestView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    layoutUI()
    configUI()
    view.addSubview(renderView)
  }
  
  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    renderView.frame = view.bounds.inset(by: view.safeAreaInsets)
  }

  @objc private func addVideo() {
    let _ = MetalInstance.makeTexture(width: 1280, height: 720)
  }
  
  @objc private func historyVideo() {
    
  }
}

extension HomeViewController {
  private func layoutUI() {
    
  }
  
  private func configUI() {
    navigationItem.title = "视频编辑"
    view.backgroundColor = UIColor.white.withAlphaComponent(243 / 255.0)
    let leftBarButtonItem = UIBarButtonItem(title: "添加",
                                            style: .plain,
                                            target: self,
                                            action: #selector(addVideo))
    navigationItem.leftBarButtonItem = leftBarButtonItem
    let rightBarButtonItem = UIBarButtonItem(title: "历史",
                                             style: .plain,
                                             target: self,
                                             action: #selector(historyVideo))
    navigationItem.rightBarButtonItem = rightBarButtonItem
  }
}
