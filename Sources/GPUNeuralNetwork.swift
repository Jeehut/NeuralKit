//
//  GPUNeuralNetwork.swift
//  NeuralKit
//
//  Created by Palle Klewitz on 04.04.17.
//	Copyright (c) 2017 Palle Klewitz
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Foundation
import Metal


public let GPUGlobalDevice = MTLCreateSystemDefaultDevice()!
public let GPUGlobalQueue = GPUGlobalDevice.makeCommandQueue()

/// A feed forward multi layer neural network
public struct GPUFeedForwardNeuralNetwork
{
	
	/// Neuron layers of the network
	public internal(set) var layers: [GPUBidirectionalLayer]
	
	public internal(set) var outputLayer: GPUOutputLayer
	
	/// Creates a new neural network using the given layers and an activation function for the output layer.
	///
	/// The input size of all layers must match the output size of their anterior layers.
	///
	/// The initialization will fail if the input and output sizes of successive layers do not match.
	///
	/// - Parameters:
	///   - layers: Layers of the neural network.
	///   - outputActivation: Activation function which should be applied at the output or nil if a linear activation function should be used
	///   - outputActivationDerivative: Derivative of the output activation function or nil if a linear activation function should be used
	public init?(layers: [GPUBidirectionalLayer], outputLayer: GPUOutputLayer, library: MTLLibrary? = nil)
	{
		guard (1..<layers.count)
			.map({layers[$0-1].outputSize == layers[$0].inputSize})
			.reduce(true, {$0 && $1})
			else
		{
			return nil
		}
		
		self.layers = layers
		self.outputLayer = outputLayer
		
		let lib = library ?? GPUGlobalDevice.newDefaultLibrary()!
		
		for index in layers.indices
		{
			self.layers[index].initialize(library: lib, shareOutput: false)
		}
		
		self.outputLayer.initialize(library: lib, shareOutput: true)
	}
	
	
	/// Feeds a sample forward through the network.
	///
	/// This applies the activation function of each layer
	/// and passes the weighted output to the next layer until
	/// the last layer has been reached.
	///
	/// The weighted result of the forward operation on the last layer
	/// will be passed through the output activation function (if set) and will be returned.
	///
	/// - Parameter sample: Input of the network
	/// - Returns: Result of the feed forward operation on the last layer
	public func feedForward(_ sample: GPUMatrix3) -> Matrix3
	{
		let buffer = GPUGlobalQueue.makeCommandBuffer()
		let encoder = buffer.makeComputeCommandEncoder()
		
		let lastHiddenLayerResult = layers.reduce(sample)
		{ layerInput, layer in
			let layerResult = layer.forward(layerInput, encoder: encoder)
			return layerResult
		}
		
		let output = outputLayer.forward(lastHiddenLayerResult, encoder: encoder)
		
		encoder.endEncoding()
		buffer.commit()
		buffer.waitUntilCompleted()
		
		return output.asMatrix()
	}
	
	
	/// Trains a network to match a given training sample more closely
	/// by backpropagating the error between the expected and actual value through the network.
	///
	/// The learning rate determines how fast the network should adapt.
	/// If it is chosen very small, the network will learn slower but also more accurately.
	///
	/// The returned error is calculated by summing the squares of the errors at each output neuron
	/// and multiplying it by 1/2.
	///
	/// **Notes**:
	/// - The momentum term is ignored unless layers use momentum based weight updates.
	/// - The delta decay term is ignored unless layers use adadelta based weight updates.
	/// - The learning rate is ignored when using adadelta based weight updates.
	///
	/// - Parameters:
	///   - sample: Sample containing the input and expected value of the network
	///   - learningRate: Rate at which the network should adapt to the sample
	/// - Returns: The total error between the expected and actual output
//	@discardableResult
//	public mutating func train(
//		_ sample: (input: GPUMatrix3, expected: GPUMatrix3),
//		learningRate: Float,
//		momentum: Float = 0,
//		decay: Float = 0,
//		deltaDecay: Float = 0
//	) -> Float
//	{
//		let buffer = GPUGlobalQueue.makeCommandBuffer()
//		let encoder = buffer.makeComputeCommandEncoder()
//		
//		var layerInputs = [sample.input]
//		
//		for layer in self.layers
//		{
//			layerInputs.append(layer.forward(layerInputs.last!, encoder: encoder))
//		}
//		
//		layerInputs.append(outputLayer.forward(layerInputs.last!, encoder: encoder))
//		
////		print("GPU actual: \(layerInputs.last!.asMatrix().values.map(String.init).joined(separator: ", "))")
//		
//		var gradient = outputLayer.loss(expected: sample.expected, actual: layerInputs.last!, encoder: encoder)
//		
////		print("GPU: \(gradient.asMatrix().values.map(String.init).joined(separator: ", "))")
//		
//		for index in layers.indices.reversed()
//		{
//			gradient = self.layers[index].backpropagate(
//				nextLayerGradients: gradient,
//				inputs: layerInputs[index],
//				encoder: encoder,
//				learningRate: learningRate,
//				momentum: momentum,
//				decay: decay,
//				deltaDecay: deltaDecay
//			)
//		}
//		
//		encoder.endEncoding()
//		buffer.commit()
//		buffer.waitUntilCompleted()
//		
//		
////		return -sum(log(layerInputs.last!.asMatrix().values) &* sample.expected.asMatrix().values)
//		if outputLayer is GPUSoftmaxLayer
//		{
//			return -sum(log(layerInputs.last!.asMatrix().values) &* sample.expected.asMatrix().values)
//		}
//		else
//		{
//			let deltas = layerInputs.last!.asMatrix().values &- sample.expected.asMatrix().values
//			return (deltas * deltas) * 0.5
//		}
//	}
	
	internal func updateGradients(with sample: (input: GPUMatrix3, expected: GPUMatrix3), encoder: MTLComputeCommandEncoder)
	{
		var layerInputs = [sample.input]
		
		for layer in self.layers
		{
			layerInputs.append(layer.forward(layerInputs.last!, encoder: encoder))
		}
		
		layerInputs.append(outputLayer.forward(layerInputs.last!, encoder: encoder))
		
		var gradient = outputLayer.loss(expected: sample.expected, actual: layerInputs.last!, encoder: encoder)
		
		for index in layers.indices.reversed()
		{
			gradient = self.layers[index].backpropagate(
				nextLayerGradients: gradient,
				inputs: layerInputs[index],
				encoder: encoder
			)
		}
	}
}
