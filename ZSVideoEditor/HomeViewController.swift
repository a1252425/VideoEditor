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
  
  private var reader: VideoReader?
  private var videoTime: TimeInterval = 0
  
  private lazy var renderView: DisplayView = {
    DisplayView(frame: view.bounds, device: MetalInstance.sharedDevice)
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    layoutUI()
    configUI()
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    print(path)
  }
  
  @objc private func addVideo() {
    guard
      let filePath = Bundle.main.path(forResource: "temp", ofType: "MP4")
    else { return }
    let reader = VideoReader(filePath)
    reader.delegate = self
    self.reader = reader
    reader.startReading()
  }
  
  @objc private func historyVideo() {
    
  }
}

extension HomeViewController: VideoReaderProtocol {
  func output(sampleBuffer: CMSampleBuffer, adopter: AVAssetWriterInputPixelBufferAdaptor) {
    guard
      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
    if videoTime == 0 {
      VideoFilter()
        .proccess(pixelBuffer: pixelBuffer,
                  adopter: adopter,
                  atTime: &videoTime)
    } else {
      let time = CMTime(seconds: currentTime + videoTime, preferredTimescale: 600)
      adopter.append(pixelBuffer, withPresentationTime: time)
    }
    print("read: \(currentTime + videoTime)")
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
  }
  
  func onFinished(url: URL) {
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    let time = "\(Date().timeIntervalSince1970).mp4"
    let filePath = URL(fileURLWithPath: documentPath + "/" + time)
    try? FileManager.default.moveItem(at: url, to: filePath)
    print("video process finished")
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
