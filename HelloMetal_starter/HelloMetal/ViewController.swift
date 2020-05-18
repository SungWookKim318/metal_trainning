/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Metal

var objectToDraw: Cube!

class ViewController: UIViewController {
  
  var device : MTLDevice!
  var metalLayer : CAMetalLayer!
  var vertexBuffer: MTLBuffer! = nil
  var pipelineState : MTLRenderPipelineState!
  var commandQueue : MTLCommandQueue!
  
  var timer : CADisplayLink!
  var lastFrameTimestamp: CFTimeInterval = 0.0

  var projectionMtx : Matrix4!
  
  /////////////////////////////////////
  //MARK: ViewDidLoad()
  override func viewDidLoad() {
    super.viewDidLoad()
    
    device = MTLCreateSystemDefaultDevice()
    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.frame = view.layer.frame
    view.layer.addSublayer(metalLayer)
    
    objectToDraw = Cube(device: device, commandQueue)
    
    let defaultLibrary = device.makeDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    let pipeLineStateDescriptor = MTLRenderPipelineDescriptor()
    pipeLineStateDescriptor.vertexFunction = vertexProgram
    pipeLineStateDescriptor.fragmentFunction = fragmentProgram
    pipeLineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipeLineStateDescriptor)
    
    commandQueue = device.makeCommandQueue()
    
    timer = CADisplayLink(target: self, selector: #selector(ViewController.newFrame(displayLink:)))
    timer.add(to: RunLoop.main, forMode: .default)
    let ratio = Float(self.view.bounds.size.width / self.view.bounds.size.height)
    projectionMtx = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: ratio, nearZ: 0.01, farZ: 100.0)
  }
  
  //MARK: RENDER()
  func render() {
    guard let drawable = metalLayer?.nextDrawable() else {
      print("impossible next drawable")
      return
    }
    
    // nil check
    if objectToDraw == nil{
      NSLog("objectToDraw is nil, can't draw")
      return
    }
    // try render
    let worldModelMartrix = Matrix4()
    worldModelMartrix.translate(0.0, y: 0.0, z: -7.0)
    worldModelMartrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)
    
    if objectToDraw.Render(commandQueue: commandQueue,
                           pipelineState: pipelineState,
                           drawable: drawable,
                           parentModeViewMatrix: worldModelMartrix,
                           projectionMatrix: projectionMtx,
                           clearColor: nil) == false {
      NSLog("Failt to Draw object. return false")
    }
  }
///////////////////////////////
  @objc func newFrame(displayLink: CADisplayLink){
    
    if lastFrameTimestamp == 0.0{
      lastFrameTimestamp = displayLink.timestamp
    }
    
    let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
    lastFrameTimestamp = displayLink.timestamp
    gameloop(timeSinceLastUpdate: elapsed)
  }
  
  func gameloop(timeSinceLastUpdate: CFTimeInterval) {
    objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    
    autoreleasepool{
      self.render()
    }
  }
}

