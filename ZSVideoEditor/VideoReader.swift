//
//  VideoReader.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import AVFoundation
import UIKit

var kZSVideoMakerOutputPath: String {
  NSTemporaryDirectory() + "/video.mp4"
}

protocol VideoReaderProtocol: AnyObject {
  func output(sampleBuffer: CMSampleBuffer,
              adopter: AVAssetWriterInputPixelBufferAdaptor)
  func onFinished(url: URL)
}

final class VideoReader {
  private let assertReader: AVAssetReader
  private let videoReaderOutput: AVAssetReaderTrackOutput
  private let videoSize: CGSize
  
  private let assertWriter: AVAssetWriter
  private let videoWriteInput: AVAssetWriterInput
  
  private let videoQueue = DispatchQueue.init(label: "com.zerosportsai.videoQueue")
  
  private let adaptor: AVAssetWriterInputPixelBufferAdaptor
  
  public weak var delegate: VideoReaderProtocol?

  init(_ filePath: String) {
    let asset = AVAsset(url: URL(fileURLWithPath: filePath))
    do {
      assertReader = try AVAssetReader(asset: asset)
    } catch {
      fatalError(error.localizedDescription)
    }
    
    guard let track = asset.tracks(withMediaType: .video).first else {
      fatalError("video file tracks error")
    }
    videoSize = track.naturalSize
    let videoReaderSettings: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferMetalCompatibilityKey as String: true
    ]
    videoReaderOutput = AVAssetReaderTrackOutput(track: track,
                                                 outputSettings: videoReaderSettings)
    if assertReader.canAdd(videoReaderOutput) {
      assertReader.add(videoReaderOutput)
    } else {
      fatalError("Reader cannot add output")
    }

    let outURL = URL(fileURLWithPath: kZSVideoMakerOutputPath)
    do {
      assertWriter = try AVAssetWriter(outputURL: outURL, fileType: .mov)
    } catch {
      fatalError(error.localizedDescription)
    }
    
    let rate = videoSize.width * videoSize.height * 4
    let writerSettings: [String: Any] = [
      AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: rate],
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoHeightKey: videoSize.height,
      AVVideoWidthKey: videoSize.width
    ]
    videoWriteInput = AVAssetWriterInput(mediaType: .video,
                                         outputSettings: writerSettings)
    videoWriteInput.transform = track.preferredTransform
    videoWriteInput.expectsMediaDataInRealTime = true
    
    if assertWriter.canAdd(videoWriteInput) {
      assertWriter.add(videoWriteInput)
    } else {
      fatalError()
    }
    
    let sourcePixelBufferAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: videoSize.width,
      kCVPixelBufferHeightKey as String: videoSize.height
    ]

    adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriteInput,
                                                   sourcePixelBufferAttributes: sourcePixelBufferAttributes)
  }

  public func startReading() {
    assertWriter.startWriting()
    assertReader.startReading()
    assertWriter.startSession(atSourceTime: CMTime.zero)

    videoWriteInput.requestMediaDataWhenReady(on: videoQueue) {
      [weak self] in
      guard let this = self else { return }
      while this.videoWriteInput.isReadyForMoreMediaData {
        guard
          let sample = this.videoReaderOutput.copyNextSampleBuffer()
        else {
          this.closeWriter()
          break
        }
        this.delegate?.output(sampleBuffer: sample, adopter: this.adaptor)
      }
    }
  }

  public func cancelReading() {
    assertReader.cancelReading()
    assertWriter.cancelWriting()
    videoWriteInput.markAsFinished()
  }

  private func closeWriter() {
    videoWriteInput.markAsFinished()
    assertWriter.finishWriting { [weak self] in
      self?.delegate?.onFinished(url: URL(fileURLWithPath: kZSVideoMakerOutputPath))
    }
    assertReader.cancelReading()
  }

  private func append(texture: MTLTexture, presentTime: CMTime) {
//    if self.adaptor.assetWriterInput.isReadyForMoreMediaData {
//      guard let pixeBufferPool = self.adaptor.pixelBufferPool else {
//        return
//      }
//      if self.processedPixelBuffer == nil {
//        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixeBufferPool, &self.processedPixelBuffer)
//      }
//      guard let pixelbuffer = self.processedPixelBuffer else {
//        return
//      }
//      CVPixelBufferLockBaseAddress(pixelbuffer, CVPixelBufferLockFlags(rawValue: 0))
//      let region = MTLRegionMake2D(0, 0, lroundf(Float(videoSize.width)), lroundf(Float(videoSize.height)))
//      let buffer = CVPixelBufferGetBaseAddress(pixelbuffer)
//      let bytesPerRow = 4 * region.size.width
//      texture.getBytes(buffer!, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
//      self.adaptor.append(pixelbuffer, withPresentationTime: presentTime)
//      CVPixelBufferUnlockBaseAddress(pixelbuffer, CVPixelBufferLockFlags(rawValue: 0))
//    }
  }
}
