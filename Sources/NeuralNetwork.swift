//
//  NeuralKit.swift
//  NeuralKit
//
//  Created by Palle Klewitz on 19.02.17.
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


/// A feed forward multi layer neural network
public struct FeedForwardNeuralNetwork
{
	
	/// Neuron layers of the network
	public internal(set) var layers: [NeuralLayer]
	
	
	/// Activation function at the output layer
	public let outputActivationFunction: Activation
	
	
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
	public init?(layers: [NeuralLayer], outputActivation: Activation = .linear)
	{
		guard (1..<layers.count)
			.map({layers[$0-1].outputSize == layers[$0].inputSize})
			.reduce(true, {$0 && $1})
		else
		{
			return nil
		}
		
		self.layers = layers
		self.outputActivationFunction = outputActivation
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
	public func feedForward(_ sample: Matrix3) -> Matrix3
	{
		let lastLayerOutput = layers.reduce(sample)
		{
			forwarded, layer in
			layer.forward(forwarded)
		}
		return lastLayerOutput.mapv(outputActivationFunction.function)
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
	/// - Parameters:
	///   - sample: Sample containing the input and expected value of the network
	///   - learningRate: Rate at which the network should adapt to the sample
	/// - Returns: The total error between the expected and actual output
	@discardableResult
	public mutating func train(_ sample: TrainingSample, learningRate: Float, annealingRate: Float = 0, momentum: Float = 0, decay: Float = 0) -> Float
	{
		// Feed forward sample, keeping results of individual layers
		
		var partialResults = Array<Matrix3>(repeating: Matrix3(repeating: 0, width: 0, height: 0, depth: 0), count: layers.count)
		
		var lastResult = sample.values
		
		for (index, layer) in layers.enumerated()
		{
			lastResult = layer.forward(lastResult)
			partialResults[index] = lastResult
		}
		
		let networkOutput = outputActivationFunction.function(lastResult.values)

		let errors: [Float]
		
		// Calculate the errors at the output layer
		if outputActivationFunction == .softmax
		{
			errors = sample.expected.values &- networkOutput
		}
		else
		{
			errors = (sample.expected.values &- networkOutput) &* outputActivationFunction.derivative(networkOutput)
		}

		let errorMatrix = Matrix3(
			values: errors,
			width: layers.last?.outputSize.width ?? 0,
			height: layers.last?.outputSize.height ?? 0,
			depth: layers.last?.outputSize.depth ?? 0
		)
		
		// Backpropagate the error through the network
		
//		print("CPU actual: \(networkOutput.map(String.init).joined(separator: ", "))")
		
		var gradient: Matrix3 = errorMatrix
		
//		print("CPU: \(gradient.values.map(String.init).joined(separator: ", "))")
		
		for index in layers.indices.reversed()
		{
			gradient = layers[index].adjustWeights(
				nextLayerGradients: gradient,
				inputs: index > 0 ? partialResults[index-1] : sample.values,
				learningRate: learningRate,
				annealingRate: annealingRate,
				momentum: momentum,
				decay: decay
			)
		}
		
//		_ = layers.indices.reversed().reduce(errorMatrix)
//		{ (errorMatrix, layerIndex) -> Matrix3 in
//			layers[layerIndex].adjustWeights(
//				nextLayerGradients: errorMatrix,
//				inputs: layerIndex > 0 ? partialResults[layerIndex-1] : sample.values,
//				learningRate: learningRate,
//				annealingRate: annealingRate,
//				momentum: momentum,
//				decay: decay
//			)
//		}
		
		// Calculate the total error
		if outputActivationFunction == .softmax
		{
			return -sum(log(networkOutput) &* sample.expected.values)
		}
		else
		{
			let deltas = networkOutput &- sample.expected.values
			return (deltas * deltas) * 0.5
		}
	}
	
}
