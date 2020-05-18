/// Copyright (c) 2020 Razeware LLC
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

import Foundation
import Metal
import QuartzCore

class ModelObject{
  // Variables
  let defaultColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
  let device : MTLDevice
  let name : String
  var vertexCount : Int
  var vertexBuffer : MTLBuffer?
  
  var time:CFTimeInterval = 0.0
  
  //MARK: Transform Infomations
  var pos = [Float](repeating: 0.0, count: 3)
  var rotate = [Float](repeating: 0.0, count: 3)
  var scale : Float = 1.0
  
  var bufferProvider: BufferProvider
  
  var texture: MTLTexture?
  lazy var samplerState: MTLSamplerState? = ModelObject.defaultSampler(device: self.device)
//MARK: Texture Sampler
  class func defaultSampler(device: MTLDevice) -> MTLSamplerState? {
    let sampler = MTLSamplerDescriptor()
    sampler.minFilter             = MTLSamplerMinMagFilter.nearest
    sampler.magFilter             = MTLSamplerMinMagFilter.nearest
    sampler.mipFilter             = MTLSamplerMipFilter.nearest
    sampler.maxAnisotropy         = 1
    sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.normalizedCoordinates = true
    sampler.lodMinClamp           = 0
    sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
    return device.makeSamplerState(descriptor: sampler)
  }
  
  // Functions
  init(name: String, vertices: Array<VertexWithColor>, device: MTLDevice) {
    var vertexData = Array<Float>()
    for vertex in vertices{
      vertexData += vertex.floatBuffer()
    }
    
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    if vertexBuffer == nil { NSLog("vertexBuffer is nil, file to make MTLbuffer")  }
    
    self.name = name
    self.device = device
    vertexCount = vertices.count
    self.texture = nil
    
    self.bufferProvider = BufferProvider(device: device,
                                         inflightBuffersCount: 3,
                                         sizeOfUniformsBuffer: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2)
  }
  
  init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture) {
    var vertexData = Array<Float>()
    for vertex in vertices{
      vertexData += vertex.floatBuffer()
    }
    
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    if vertexBuffer == nil { NSLog("vertexBuffer is nil, file to make MTLbuffer")  }
    
    self.name = name
    self.device = device
    vertexCount = vertices.count
    self.texture = texture
    
    self.bufferProvider = BufferProvider(device: device,
                                         inflightBuffersCount: 3,
                                         sizeOfUniformsBuffer: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2)
  }
  //MARK: Render
  func Render(commandQueue: MTLCommandQueue,
              pipelineState: MTLRenderPipelineState,
              drawable: CAMetalDrawable,
              parentModeViewMatrix: Matrix4,
              projectionMatrix: Matrix4,
              clearColor: MTLClearColor?) -> Bool {
    
    _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = clearColor ?? defaultColor
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    guard let commandBuffer = commandQueue.makeCommandBuffer() else { return false }
    commandBuffer.addCompletedHandler( {(_) in self.bufferProvider.avaliableResourcesSemaphore.signal()} )
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return false }
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    renderEncoder.setCullMode(MTLCullMode.front)
    renderEncoder.setFragmentTexture(texture, index: 0)
    if let samplerState = samplerState{
      renderEncoder.setFragmentSamplerState(samplerState, index: 0)
    }
    
    //Uniform
    let modelMtx = self.GetModelMatrix()
    modelMtx.multiplyLeft(parentModeViewMatrix)
    let uniformBuffer = bufferProvider.NextUniformsBuffer(projectMatrix: projectionMatrix, modelViewMatrix: modelMtx)
    
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

    
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
    renderEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()
    
    return true
  }
  //MARK: ModelMatrix
  func GetModelMatrix() -> Matrix4 {
    let m = Matrix4()
    m.translate(pos[0], y: pos[1], z: pos[2])
    m.rotateAroundX(rotate[0], y: rotate[1], z: rotate[2])
    m.scale(scale, y: scale, z: scale)
    return m
  }
  
  ///////////////////////////////
  func updateWithDelta(delta: CFTimeInterval){
      time += delta
  }
}
