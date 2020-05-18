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

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
  packed_float3 pos;
  packed_float4 rgba;
  packed_float2 st;
};
struct VertexOut{
  float4 pos [[position]];
  float4 rgba;
  float2 st;
};
struct Uniforms
{
  float4x4 model;
  float4x4 projection;
};

vertex VertexOut basic_vertex( const device VertexIn* vertex_array [[ buffer(0) ]],
                               const device Uniforms& uniforms [[buffer(1)]],
                               unsigned int vid [[ vertex_id ]])
{
  float4x4 p = uniforms.projection;
  float4x4 m = uniforms.model;
  
  VertexIn inVal = vertex_array[vid];
  
  VertexOut out;
  out.pos = p * m * float4(inVal.pos, 1);
  out.rgba = inVal.rgba;
  out.st = inVal.st;
  
  return out;
}

fragment float4 basic_fragment(VertexOut outVal [[stage_in]],
                              texture2d<float> tex2D [[texture(0)]],
                              sampler sampler2D[[sampler(0)]] ) {  //1
  float4 rgba = tex2D.sample(sampler2D, outVal.st);
  return rgba;
  //return half4(outVal.rgba[0], outVal.rgba[1], outVal.rgba[2], outVal.rgba[3]); //2
}
