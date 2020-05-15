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

import Metal

class BufferProvider{
  let inflightBuffersCount : Int

  private var uniformsBuffers: [MTLBuffer]
  private var avaliableBufferIndex: Int = 0
  var avaliableResourcesSemaphore: DispatchSemaphore

  //////
  init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
    avaliableResourcesSemaphore = DispatchSemaphore(value:inflightBuffersCount)
    self.inflightBuffersCount = inflightBuffersCount
    uniformsBuffers = [MTLBuffer]()
    
    for _ in 0...inflightBuffersCount - 1 {
      guard let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: []) else { return }
      uniformsBuffers.append(uniformsBuffer)
    }
  }
  //////
  func NextUniformsBuffer(projectMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
    let buffer = uniformsBuffers[avaliableBufferIndex]
    let bufferPointer = buffer.contents()
    
    memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
    memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(),
           projectMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
    
    avaliableBufferIndex += 1
    if avaliableBufferIndex == inflightBuffersCount{
      avaliableBufferIndex = 0
    }
    
    return buffer
  }
  deinit {
    for _ in 0...self.inflightBuffersCount{
      self.avaliableResourcesSemaphore.signal()
    }
  }
}

