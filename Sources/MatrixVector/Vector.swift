//
//  VectorCore.swift
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
import Accelerate


/// Operator for component wise division of a vector.
infix operator &/ : MultiplicationPrecedence

infix operator &+= : AssignmentPrecedence
infix operator &-= : AssignmentPrecedence

//MARK: Vector prefix functions

/// Negates every element of the input vector
///
/// - Parameter values: Input vector which should be negated
/// - Returns: Vector containing the negated elements of the input vector
public prefix func -(values: [Float]) -> [Float]
{
	var output = values
	vDSP_vneg(values, 1, &output, 1, UInt(values.count))
	return output
}


//MARK: Vector - Vector arithmetic

/// Calculates the dot product of two vectors.
///
/// - Parameters:
///   - lhs: First input vector
///   - rhs: Second input vector
/// - Returns: The dot product of the input vectors
public func * (lhs: [Float], rhs: [Float]) -> Float
{
	var output: Float = 0
	vDSP_dotpr(lhs, 1, rhs, 1, &output, UInt(lhs.count))
	return output
}


/// Performs a component wise addition of two input vectors
///
/// - Parameters:
///   - lhs: First input vector
///   - rhs: Second input vector
/// - Returns: Output vector generated by adding the input vectors component wise.
public func &+ (lhs: [Float], rhs: [Float]) -> [Float]
{
	precondition(lhs.count == rhs.count, "Vector lengths must be equal")
	
	var output = lhs
	vDSP_vadd(lhs, 1, rhs, 1, &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise subtraction of two input vectors
///
/// - Parameters:
///   - lhs: First input vector
///   - rhs: Second input vector
/// - Returns: Output vector generated by subtracting the input vectors component wise.
public func &- (lhs: [Float], rhs: [Float]) -> [Float]
{
	precondition(lhs.count == rhs.count, "Vector lengths must be equal")
	
	var output = lhs
	vDSP_vsub(rhs, 1, lhs, 1, &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise multiplication of two input vectors
///
/// - Parameters:
///   - lhs: First input vector
///   - rhs: Second input vector
/// - Returns: Output vector generated by multiplying the input vectors component wise.
public func &* (lhs: [Float], rhs: [Float]) -> [Float]
{
	precondition(lhs.count == rhs.count, "Vector lengths must be equal")
	
	var output = lhs
	vDSP_vmul(lhs, 1, rhs, 1, &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise division of two input vectors
///
/// - Parameters:
///   - lhs: First input vector
///   - rhs: Second input vector
/// - Returns: Output vector generated by dividing the input vectors component wise.
public func &/ (lhs: [Float], rhs: [Float]) -> [Float]
{
	precondition(lhs.count == rhs.count, "Vector lengths must be equal")
	
	var output = lhs
	vDSP_vdiv(lhs, 1, rhs, 1, &output, 1, UInt(lhs.count))
	return output
}


//MARK: Vector - Scalar arithmetic


/// Performs a component wise addition of an input vector with a scalar
///
/// - Parameters:
///   - lhs: Input vector
///   - rhs: Input scalar
/// - Returns: Output vector generated by adding the input scalar to the components of the input vector.
public func &+ (lhs: [Float], rhs: Float) -> [Float]
{
	var output = lhs
	vDSP_vsadd(lhs, 1, [rhs], &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise subtraction of an input vector with a scalar
///
/// - Parameters:
///   - lhs: Input vector
///   - rhs: Input scalar
/// - Returns: Output vector generated by subtracting the input scalar from the components of the input vector.
public func &- (lhs: [Float], rhs: Float) -> [Float]
{
	var output = lhs
	vDSP_vsadd(lhs, 1, [-rhs], &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise multiplication of an input vector with a scalar
///
/// - Parameters:
///   - lhs: Input vector
///   - rhs: Input scalar
/// - Returns: Output vector generated by multiplying the input scalar with the components of the input vector.
public func &* (lhs: [Float], rhs: Float) -> [Float]
{
	var output = lhs
	vDSP_vsmul(lhs, 1, [rhs], &output, 1, UInt(lhs.count))
	return output
}


/// Performs a component wise division of an input vector with a scalar
///
/// - Parameters:
///   - lhs: Input vector
///   - rhs: Input scalar
/// - Returns: Output vector generated by dividing the input vector by the input scalar
public func &/ (lhs: [Float], rhs: Float) -> [Float]
{
	var output = lhs
	vDSP_vsdiv(lhs, 1, [rhs], &output, 1, UInt(lhs.count))
	return output
}


//MARK: Scalar - Vector arithmetic

/// Performs a component wise addition of an input vector and a scalar
///
/// - Parameters:
///   - lhs: Input scalar
///   - rhs: Input vector
/// - Returns: Output vector generated by adding the input scalar to every element of the input vector.
public func &+ (lhs: Float, rhs: [Float]) -> [Float]
{
	var output = rhs
	vDSP_vsadd(rhs, 1, [lhs], &output, 1, UInt(rhs.count))
	return output
}


/// Performs a component wise subtraction of an input scalar and a vector
///
/// - Parameters:
///   - lhs: Input scalar
///   - rhs: Input vector
/// - Returns: Output vector generated by subtracting every element from the input scalar.
public func &- (lhs: Float, rhs: [Float]) -> [Float]
{
	var output = rhs
	vDSP_vneg(rhs, 1, &output, 1, UInt(rhs.count))
	vDSP_vsadd(output, 1, [lhs], &output, 1, UInt(rhs.count))
	return output
}


/// Performs a component wise multiplication of an input vector and a scalar
///
/// - Parameters:
///   - lhs: Input scalar
///   - rhs: Input vector
/// - Returns: Output vector generated by multiplying the input scalar with every element of the input vector.
public func &* (lhs: Float, rhs: [Float]) -> [Float]
{
	var output = rhs
	vDSP_vsmul(rhs, 1, [lhs], &output, 1, UInt(rhs.count))
	return output
}


/// Performs a component wise division of an input scalar and a vector
///
/// - Parameters:
///   - lhs: Input scalar
///   - rhs: Input vector
/// - Returns: Output vector generated by dividing the input scalar by every element of the input vector.
public func &/ (lhs: Float, rhs: [Float]) -> [Float]
{
	var output = rhs
	vDSP_svdiv([lhs], rhs, 1, &output, 1, UInt(rhs.count))
	return output
}


/// Performs a component wise in place addition of two input vectors.
/// The result will be stored in the first input vector
///
/// - Parameters:
///   - lhs: First input and result vector
///   - rhs: Second input vector
public func &+= (lhs: inout [Float], rhs: [Float])
{
	vDSP_vadd(lhs, 1, rhs, 1, &lhs, 1, UInt(lhs.count))
}


/// Performs a component wise in place subtraction of the two input vectors.
/// The result will be stored in the first input vector.
///
/// - Parameters:
///   - lhs: First input and result vector
///   - rhs: Second input vector
public func &-= (lhs: inout [Float], rhs: [Float])
{
	vDSP_vsub(rhs, 1, lhs, 1, &lhs, 1, UInt(lhs.count))
}


//MARK: Vector functions commonly used in neural networks

/// Calculates the element wise square root of an input vector
///
/// - Parameter values: Input vector
/// - Returns: Output vector containing the roots of every element of the input vector
public func sqrt(_ values: [Float]) -> [Float]
{
	var output = values
	vvsqrtf(&output, values, [Int32(values.count)])
	return output
}


/// Calculates the exponential function e^x for every element x of the input vector
///
/// - Parameter values: Input vector
/// - Returns: Output vector containing the exponentiated elements of the input vector
public func exp(_ values: [Float]) -> [Float]
{
	var output = values
	vvexpf(&output, values, [Int32(values.count)])
	return output
}


/// Calculates the tangens hyperbolicus for every element of the input vector
///
/// - Parameter values: Input vector
/// - Returns: Output vector containing the tangens hyperbolicus of every element from the input vector
public func tanh(_ values: [Float]) -> [Float]
{
	var output = values
	vvtanhf(&output, values, [Int32(values.count)])
	return output
}


/// Calculates the derivative of the tangens hyperbolicus for every element of the input vector.
///
/// **Note:** The input vector must consist of output values from the tanh function.
///
/// - Parameter values: Values for which the derivative of the tangens hyperbolicus should be calculated
/// - Returns: The derivative of the tangens hyperbolicus of every element in the input vector.
public func tanh_deriv(_ values: [Float]) -> [Float]
{
	var output = values
	vDSP_vsq(values, 1, &output, 1, vDSP_Length(values.count))
	vDSP_vneg(output, 1, &output, 1, vDSP_Length(values.count))
	vDSP_vsadd(output, 1, [1], &output, 1, vDSP_Length(values.count))
	return output
}


/// Calcualtes the natural logarithm of every element of the input vector
///
/// - Parameter values: Input vector
/// - Returns: Output vector containing the natural logarithm of every element from the input vector
public func log(_ values: [Float]) -> [Float]
{
	var output = values
	vvlogf(&output, values, [Int32(values.count)])
	return output
}


/// Raises each element of the base vector to its corresponding element of the exponent vector
///
/// - Parameters:
///   - base: Base vector
///   - exponent: Exponent vector
/// - Returns: Vector generated by performing a component wise power operation with the given base and exponent
public func pow(_ base: [Float], _ exponent: [Float]) -> [Float]
{
	var output = base
	vvpowf(&output, base, exponent, [Int32(base.count)])
	return output
}


/// Sets the sign on the values of the first vector based on the sign of the second vector
///
/// - Parameters:
///   - magnitudes: Magnitudes of the resulting vector. The sign is ignored.
///   - signs: Signs of the resulting vector. The magnitude is ignored.
/// - Returns: Vector containing values with the magnitude determined by the first vector and the sign determined by the second vector.
public func copysign(_ magnitudes: [Float], _ signs: [Float]) -> [Float]
{
	var output = magnitudes
	vvcopysignf(&output, magnitudes, signs, [Int32(output.count)])
	return output
}


/// Computes a rectified linear unit activation function
/// The output values will be equal to max(input, 0)
///
/// - Parameter values: Input vector
/// - Returns: Output values generated by applying max(input, 0) to each value of the input vector.
public func relu(_ values: [Float]) -> [Float]
{
	var output = values
	vDSP_vthres(values, 1, [0], &output, 1, UInt(values.count))
	return output
}


/// Computes the derivative of a rectified linear unit activation function
/// Using raw input values or output values of the rectified linear unit function
///
/// - Parameter values: Input vector
/// - Returns: Output values generated by calculating the derivative 
/// of the rectified linear unit function for each value of the input vector.
public func relu_deriv(_ values: [Float]) -> [Float]
{
	var output = values
	vDSP_vclip(values, 1, [0], [1], &output, 1, UInt(values.count))
	vvceilf(&output, output, [Int32(values.count)])
	return output
}


/// Returns the unchanged input values
///
/// - Parameter values: Input values
/// - Returns: The unchanged input values
@inline(__always)
public func identity(_ values: [Float]) -> [Float]
{
	return values
}


/// Returns a vector containing ones with the same length as the input vector
///
/// - Parameter values: Input vector
/// - Returns: Vector of ones with the same length as the input vector
@inline(__always)
public func ones(_ values: [Float]) -> [Float]
{
	return Array<Float>(repeating: 1, count: values.count)
}


/// Returns a vector containing zeros with the same length as the input vector
///
/// - Parameter values: Input vector
/// - Returns: Vector of zeros with the same length as the input vector
@inline(__always)
public func zeros(_ values: [Float]) -> [Float]
{
	return Array<Float>(repeating: 0, count: values.count)
}


/// Calculates the sigmoid function for every element of the input vector
///
/// - Parameter values: Input vector
/// - Returns: Vector containing the sigmoid function results of the values of the input values
public func sigmoid(_ values: [Float]) -> [Float]
{
	return 1 &/ (exp(-values) &+ 1)
}


/// Calculates the derivative of the sigmoid function of the input vector.
/// The input vector must contain values which are already outputs of the sigmoid function
///
/// - Parameter values: Sigmoid input value vector
/// - Returns: Vector containing the derivatives of the sigmoid function for every sigmoid function value of the input vector
public func sigmoid_deriv(_ values: [Float]) -> [Float]
{
	return values &* (1 &- values)
}


/// Calculates the sum of all elements of a vector
///
/// - Parameter values: Vector of values to sum up
/// - Returns: Sum of all elements of the input vector
public func sum(_ values: [Float]) -> Float
{
	var sum: Float = 0
	vDSP_sve(values, 1, &sum, UInt(values.count))
	return sum
}


/// Calculates the softmax function for every element of the input vector
///
/// - Parameter values: Input vector
/// - Returns: Result vector
public func softmax(_ values: [Float]) -> [Float]
{
	// shifting to small number values for numerical stability
	let shifted = values &- max(values)
	let exponentiated = exp(shifted)
	let summed = sum(exponentiated)
	return exponentiated &/ summed
}


/// Calculates the derivative of the softmax function for every element of the input vector
/// The input vector must contain values which are already outputs of the softmax function
///
/// - Parameter values: Input vector
/// - Returns: Derivative of the softmax function for every softmax value of the input vector
public func softmax_deriv(_ values: [Float]) -> [Float]
{
	fatalError()
	
//	var jacobian = Matrix(repeating: 0, width: values.count, height: values.count)
//	
//	for (x,y) in jacobian.indices
//	{
//		jacobian[x,y] = values[x] * ((x == y ? 1 : 0) - values[y])
//	}
//	
//	return jacobian * values
}


//MARK: Maxima and minima


/// Finds the maximum value of a vector
///
/// - Parameter values: Input vector
/// - Returns: Maximum value of the vector
public func max(_ values: [Float]) -> Float
{
	var max: Float = 0
	vDSP_maxv(values, 1, &max, UInt(values.count))
	return max
}


/// Finds the minimum value of a vector
///
/// - Parameter values: Input vector
/// - Returns: Minimum value of the vector
public func min(_ values: [Float]) -> Float
{
	var min: Float = 0
	vDSP_minv(values, 1, &min, UInt(values.count))
	return min
}


/// Finds the maximum value and its index of a vector
///
/// - Parameter values: Input vector
/// - Returns: Maximum value and its index
public func argmax(_ values: [Float]) -> (Float, Int)
{
	var max:Float = 0
	var ind:UInt = 0
	vDSP_maxvi(values, 1, &max, &ind, UInt(values.count))
	return (max, Int(ind))
}


/// Finds the minimum value and its index of a vector
///
/// - Parameter values: Input vector
/// - Returns: Minimum value and its index
public func argmin(_ values: [Float]) -> (Float, Int)
{
	var min:Float = 0
	var ind:UInt = 0
	vDSP_minvi(values, 1, &min, &ind, UInt(values.count))
	return (min, Int(ind))
}
