//
//  MatrixCore.swift
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


/// A two dimensional matrix
public struct Matrix
{
	
	/// Values stored in the matrix as a flattened array. 
	/// The value of the nth row and mth column is at index `n * width + m`
	public internal(set) var values: [Float]
	
	
	/// Width of the matrix
	/// If the width is zero, the matrix is empty for any height
	public let width: Int
	
	
	/// Height of the matrix
	/// If the height is zero, the matrix is empty for any width
	public let height: Int
	
	
	/// Indices of the matrix in the form (column,row)
	///
	/// This can be used to avoid nested loops on index based iteration:
	///
	///		for (column, row) in matrix.indices {
	///			let value = matrix[column, row]
	///			...
	///		}
	///
	/// The number of possible indices is equal to width * height of the matrix
	public var indices:[(Int,Int)]
	{
		func combine<BoundA: Comparable, BoundB: Comparable>(_ a: CountableRange<BoundA>, _ b: CountableRange<BoundB>) -> [(BoundA,BoundB)]
		{
			return b.flatMap{elB in a.map{($0,elB)}}
		}
		return combine(0..<width,0..<height)
	}
	
	/// Creates a new matrix with a given width and height
	/// containing the given values.
	/// The value stored at a row n and a column n must be at index `n * width + m` in the input vector.
	///
	/// The product of width and height must be equal to the number of elements in the input vector.
	///
	/// - Parameters:
	///   - values: Input vector containing the matrix values
	///   - width: Width of the matrix
	///   - height: Height of the matrix
	public init(values: [Float], width: Int, height: Int)
	{
		precondition(width * height == values.count, "Matrix dimensions are incorrect")
		self.values = values
		self.width = width
		self.height = height
	}
	
	
	/// Creates a new matrix with the given rows.
	///
	/// - Parameter rows: row vectors of equal length
	public init(rows: [[Float]])
	{
		self.values = rows.flatMap{$0}
		self.width = rows.first?.count ?? 0
		self.height = rows.count
		
		assert(rows.reduce(true, {$0 && $1.count == self.width}), "The length of all rows must be equal")
	}
	
	
	/// Initializes a two dimensional matrix from a three dimensional tensor
	/// which must have a depth of 1.
	///
	/// - Parameter matrix: Source tensor
	public init(_ matrix: Matrix3)
	{
		precondition(matrix.depth == 1, "Source matrix must have depth of 1.")
		
		self.width = matrix.width
		self.height = matrix.height
		self.values = matrix.values
	}
	
	
	/// Initializes a matrix with the given dimensions and sets every value to the repeating value.
	///
	/// - Parameters:
	///   - repeating: Value to which every field of the new matrix will be set
	///   - width: Width of the matrix
	///   - height: Height of the matrix
	public init(repeating: Float, width: Int, height: Int)
	{
		self.values = Array<Float>(repeating: repeating, count: width * height)
		self.width = width
		self.height = height
	}
	
	
	/// Multiplies a matrix with another matrix.
	/// The resulting matrix will have a width equal to the height of the left matrix 
	/// and a height equal to the width of the right matrix.
	///
	/// The width of the left matrix must be equal to the height of the right matrix
	///
	/// - Parameters:
	///   - lhs: Left matrix
	///   - rhs: Right matrix
	/// - Returns: A matrix generated by multiplying the left matrix with the right matrix
	public static func * (lhs: Matrix, rhs: Matrix) -> Matrix
	{
		precondition(lhs.width == rhs.height, "Width of left matrix must be equal to height of right matrix.")
		
		var result = [Float](repeating: 0, count: lhs.height * rhs.width)
		vDSP_mmul(lhs.values, 1, rhs.values, 1, &result, 1, vDSP_Length(lhs.height), vDSP_Length(rhs.width), vDSP_Length(lhs.width))
		return Matrix(values: result, width: rhs.width, height: lhs.height)
	}
	
	
	/// Multiplies a matrix with a vector
	///
	/// The width of the matrix must be equal to the length of the vector.
	/// The resulting vector will have a length equal to the height of the matrix
	///
	/// - Parameters:
	///   - lhs: Matrix to multiply
	///   - rhs: Vector, which is multiplied with the matrix
	/// - Returns: A vector generated by multiplying the input matrix with the input vector
	public static func * (lhs: Matrix, rhs: [Float]) -> [Float]
	{
		precondition(lhs.width == rhs.count, "Length of vector must be equal to width of matrix.")
		
		var result = [Float](repeating: 0, count: lhs.height)
		cblas_sgemv(CblasRowMajor, CblasNoTrans, Int32(lhs.height), Int32(lhs.width), 1.0, lhs.values, Int32(lhs.width), rhs, 1, 1.0, &result, 1)
		return result
	}
	
	
	/// Multiplies a matrix with another matrix.
	///
	/// - Parameters:
	///   - lhs: First Matrix
	///   - rhs: Second Matrix
	///   - transposeFirst: Specifies whether the first matrix should be transposed before multiplying
	///   - transposeSecond: Specifies whether the second matrix should be transposed before multiplying
	///   - scale: Scaling factor applied to the result
	/// - Returns: Product of the two input matrices
	public static func multiply(_ lhs: Matrix, _ rhs: Matrix, transposeFirst: Bool = false, transposeSecond: Bool = false, scale: Float = 1.0) -> Matrix
	{
		var result = [Float](repeating: 0, count: (transposeFirst ? lhs.width : lhs.height) * (transposeSecond ? rhs.height : rhs.width))
		cblas_sgemm(
			CblasRowMajor,
			transposeFirst ? CblasTrans : CblasNoTrans,
			transposeSecond ? CblasTrans : CblasNoTrans,
			Int32(lhs.height),
			Int32(rhs.width),
			Int32(lhs.width),
			scale,
			lhs.values,
			Int32(lhs.width),
			rhs.values,
			Int32(rhs.width),
			0,
			&result,
			Int32(rhs.width)
		)
		return Matrix(values: result, width: rhs.width, height: lhs.height)
	}
	
	
	/// Multiplies a matrix with a vector
	///
	/// The width of the matrix must be equal to the length of the vector.
	/// The resulting vector will have a length equal to the height of the matrix
	///
	/// - Parameters:
	///   - lhs: Matrix to multiply
	///   - rhs: Vector, which is multiplied with the matrix
	///   - transpose: Specifies whether the matrix should be transposed before multiplying
	///   - scale: Scaling factor applied to the result
	/// - Returns: A vector generated by multiplying the input matrix with the input vector
	public static func multiply(_ lhs: Matrix, _ rhs: [Float], transpose: Bool = false, scale: Float = 1.0) -> [Float]
	{
		var result = [Float](repeating: 0, count: transpose ? lhs.width : lhs.height)
		cblas_sgemv(
			CblasRowMajor,
			transpose ? CblasTrans : CblasNoTrans,
			Int32(lhs.height),
			Int32(lhs.width),
			scale,
			lhs.values,
			Int32(lhs.width),
			rhs,
			1,
			0,
			&result,
			1
		)
		return result
	}
	
	
	/// Performs an element wise addition of two matrices of equal dimensions.
	///
	/// The second matrix can be scaled using the secondScale factor.
	///
	/// - Parameters:
	///   - lhs: First Matrix
	///   - rhs: Second Matrix
	///   - secondScale: Scaling factor for the second matrix
	/// - Returns: Matrix generated by summing values at equal positions from the two input matrices
	public static func add(_ lhs: Matrix, _ rhs: Matrix, secondScale: Float = 1.0) -> Matrix
	{
		precondition(lhs.width == rhs.width && lhs.height == rhs.height, "Matrices must have equal dimensions")
		
		var result = lhs.values
		vDSP_vsma(rhs.values, 1, [secondScale], lhs.values, 1, &result, 1, UInt(lhs.values.count))
		return Matrix(values: result, width: lhs.width, height: rhs.height)
	}
	
	
	/// Adds the matrix to the base matrix in place.
	///
	/// - Parameter other: Matrix which should be added to the base matrix.
	public mutating func add(_ other: Matrix)
	{
		precondition(self.width == other.width && self.height == other.height, "Matrices must have equal dimensions")
		
		vDSP_vadd(self.values, 1, other.values, 1, &self.values, 1, UInt(self.values.count))
	}
	
	
	/// Multiplies the matrix with the scalar factor and adds it onto the base matrix
	/// in place
	///
	/// - Parameters:
	///   - other: Matrix which should be added to the base matrix
	///   - factor: Scale at which the matrix will be added
	public mutating func add(_ other: Matrix, factor: Float)
	{
		vDSP_vsma(other.values, 1, [factor], self.values, 1, &self.values, 1, UInt(self.values.count))
	}
	
	
	/// Multiplies the two input matrices and adds them to the base matrix with the given factor
	///
	/// - Parameters:
	///   - first: First matrix to multiply
	///   - second: Second matrix to multiply
	///   - transposeFirst: Specifies if the first matrix should be transposed
	///   - transposeSecond: Specifies if the second matrix should be transposed
	///   - factor: Factor applied to the result of the multiplication before adding it to the base matrix
	///   - destinationFactor: Factor applied to the destination before adding the result of the multiplication
	public mutating func addMultiplied(_ first: Matrix, _ second: Matrix, transposeFirst: Bool = false, transposeSecond: Bool = false, factor: Float = 1.0, destinationFactor: Float = 1.0)
	{
		precondition((transposeFirst ? first.height : first.width) == (transposeSecond ? second.width : second.height), "Width of first matrix must equal height of second matrix.")
		precondition((transposeFirst ? first.width : first.height) == self.height, "Height of first input matrix must be equal to height of destination matrix.")
		precondition((transposeSecond ? second.height : second.width) == self.width, "Width of second input matrix must be equal to width of destination matrix.")
		
		cblas_sgemm(
			CblasRowMajor,
			transposeFirst ? CblasTrans : CblasNoTrans,
			transposeSecond ? CblasTrans : CblasNoTrans,
			Int32(first.height),
			Int32(second.width),
			Int32(first.width),
			factor,
			first.values,
			Int32(first.width),
			second.values,
			Int32(second.width),
			destinationFactor,
			&self.values,
			Int32(self.width)
		)
	}
	
	
	/// Performs an element wise addition of two matrices of equal dimensions
	///
	/// - Parameters:
	///   - lhs: First matrix
	///   - rhs: Second matrix
	/// - Returns: Matrix generated by summing values at equal positions from the two input matrices
	public static func + (lhs: Matrix, rhs: Matrix) -> Matrix
	{
		precondition(lhs.width == rhs.width && lhs.height == rhs.height, "Matrices must have equal dimensions")
		
		return Matrix(values: lhs.values &+ rhs.values, width: lhs.width, height: lhs.height)
	}
	
	
	/// Performs an element wise addition of two matrices of equal dimensions
	/// and stores the result in the first matrix
	///
	/// - Parameters:
	///   - lhs: First matrix
	///   - rhs: Second matrix
	public static func += (lhs: inout Matrix, rhs: Matrix)
	{
		lhs.add(rhs)
	}
	
	
	/// Multiplies every element of the matrix with the scalar and writes it back to the matrix.
	///
	/// - Parameters:
	///   - lhs: Matrix to multiply
	///   - rhs: Scaling factor
	public static func *= (lhs: inout Matrix, rhs: Float)
	{
		vDSP_vsmul(lhs.values, 1, [rhs], &lhs.values, 1, UInt(lhs.values.count))
	}
	
	
	/// Subscript for accessing a single field of the matrix 
	/// at the given horizontal and vertical position.
	///
	/// - Parameters:
	///   - x: Horizontal index
	///   - y: Vertical index
	public subscript(x: Int, y: Int) -> Float
	{
		get
		{
			guard 0 ..< width ~= x, 0 ..< height ~= y else
			{
				return 0
			}
			return values[width * y + x]
		}
		
		set (new)
		{
			guard 0 ..< width ~= x, 0 ..< height ~= y else
			{
				return
			}
			values[width * y + x] = new
		}
	}
	
	
	/// Subscript for accessing a row of the matrix
	///
	/// - Parameter row: Index of the row which should be retrieved or set
	public subscript(row row: Int) -> [Float]
	{
		get
		{
			return Array<Float>(values[(row * width) ..< ((row + 1) * width)])
		}
		
		set (new)
		{
			values[(row*width) ..< ((row+1) * width)] = new[0 ..< width]
		}
	}
	
	
	/// Subscript for accessing a column of the matrix
	///
	/// - Parameter column: Index of the column which should be retrieved or set
	public subscript(column column: Int) -> [Float]
	{
		get
		{
			var result = [Float](repeating: 0, count: height)
			for y in (0 ..< height)
			{
				result[y] = values[width * y + column]
			}
			return result
		}
		
		set (new)
		{
			for i in 0 ..< height
			{
				values[width * i + column] = new[i]
			}
		}
	}
	
	
	/// Subscript for accessing a submatrix of the matrix
	///
	/// - Parameters:
	///   - column: Starting column of the submatrix
	///   - row: Starting row of the submatrix
	///   - width: Width of the submatrix
	///   - height: Height of the submatrix
	public subscript(column column: Int, row row: Int, width width: Int, height height: Int) -> Matrix
	{
		get
		{
			var result = Matrix(repeating: 0, width: width, height: height)
			
			for (x,y) in result.indices where 0 ..< self.width ~= x + column && 0 ..< self.height ~= y + row
			{
				result[x,y] = self[x+column, y+row]
			}
			
			return result
		}
		
		set (new)
		{
			for (x,y) in new.indices where 0 ..< self.width ~= x + column && 0 ..< self.height ~= y + row
			{
				self[x+column, y+row] = new[x,y]
			}
		}
	}
	
	
	/// The transposed matrix generated by swapping all fields (i,j) with (j,i).
	public var transposed: Matrix
	{
		var result = self.values
		vDSP_mtrans(self.values, 1, &result, 1, vDSP_Length(width), vDSP_Length(height))
		return Matrix(values: result, width: height, height: width)
	}
	
	
	/// Performs a convolution of the matrix using the provided convolution kernel
	///
	/// - Parameters:
	///   - kernel: Convolution kernel
	///   - horizontalStride: Horizontal stride at which the source matrix is traversed
	///   - verticalStride: Vertical stride at which the source matrix is traversed
	///   - lateralStride: Lateral stride at which the source matrix is traversed
	///   - horizontalInset: Horizontal inset at which the traversion begins and ends
	///   - verticalInset: Vertical inset at which the traversion begins and ends
	///   - lateralInset: Lateral inset at which the traversion begins and ends
	/// - Returns: Result of the convolution operation
	public func convolved(
		with kernel: Matrix,
		horizontalStride: Int = 1,
		verticalStride: Int = 1,
		horizontalInset: Int = 0,
		verticalInset: Int = 0
		) -> Matrix
	{
		var output = Matrix(
			repeating: 0,
			width:  self.width  / horizontalStride - kernel.width  + 1 - 2 * horizontalInset,
			height: self.height / verticalStride   - kernel.height + 1 - 2 * verticalInset
		)
		
		for (x,y) in output.indices
		{
			let source = self[
				column:	x * horizontalStride + horizontalInset,
				row:	y * verticalStride	 + verticalInset,
				width:	kernel.width,
				height: kernel.height
			]
			output[x,y] = source.values * kernel.values
		}
		
		return output
	}
	
	
	/// Performs a correlation
	///
	/// - Parameters:
	///   - kernel: Correlation kernel
	///   - horizontalStride: Horizontal stride at which the destination matrix is traversed
	///   - verticalStride: Vertical stride at which the destination matrix is traversed
	///   - horizontalInset: Horizontal inset at which the traversion begins and ends
	///   - verticalInset: Vertical inset at which the traversion begins and ends
	/// - Returns: Correlated matrix
	public func correlated(
		with kernel: Matrix,
		horizontalStride: Int = 1,
		verticalStride: Int = 1,
		horizontalInset: Int = 0,
		verticalInset: Int = 0
	) -> Matrix
	{
		var result = Matrix(
			repeating: 0,
			width:  self.width  * horizontalStride + kernel.width  - 1 + 2 * horizontalInset,
			height: self.height * verticalStride   + kernel.height - 1 + 2 * verticalInset
		)
		
		let reversedKernel = kernel.reversed()
		
		for (x,y) in self.indices
		{
			let source = self[x,y]
			let correlated = reversedKernel.mapv{$0 &* source}
			result[
				column: x * horizontalStride + horizontalInset,
				row:    y * verticalStride   + verticalInset,
				width:  kernel.width,
				height: kernel.height
			] += correlated
		}
		
		return result
	}
	
	
	/// Reverses the matrix. The element at position (i,j,k) will be at (width-i,height-j,depth-k)
	/// in the resulting matrix.
	///
	/// - Returns: Matrix generated by reversing a matrix.
	public func reversed() -> Matrix
	{
		return Matrix(values: self.values.reversed(), width: self.width, height: self.height)
	}
	
	
	/// Returns a matrix generated from a matrix by applying the transform function to every element
	///
	/// - Parameter transform: Transform function which will be applied on every element
	/// - Returns: Matrix generated by applying the transform function to the elements of the initial matrix
	public func map(_ transform: (Float) throws -> Float) rethrows -> Matrix
	{
		return try Matrix(values: self.values.map(transform), width: width, height: height)
	}
	
	
	/// Returns a matrix generated from a matrix by applying the vectorized transform function to every element
	///
	/// - Parameter transform: Vectorized transform function which will be applied on every element
	/// - Returns: Matrix generated by applying the transform function to the elements of the initial matrix
	public func mapv(_ transform: ([Float]) throws -> [Float]) rethrows -> Matrix
	{
		return try Matrix(values: transform(self.values), width: width, height: height)
	}
	
	
	/// Reshapes the matrix into a new matrix containing the same values.
	///
	/// The reshaped matrix must store the same number of values as the source matrix
	///
	/// - Parameters:
	///   - width: Width of the reshaped matrix
	///   - height: Height of the reshaped matrix
	/// - Returns: Reshaped matrix
	public func reshaped(width: Int, height: Int) -> Matrix
	{
		precondition(
			width * height == self.width * self.height,
			"Number of values in reshaped matrix must be equal to number of values in source matrix"
		)
		return Matrix(values: self.values, width: width, height: height)
	}
	
}


extension Matrix: CustomStringConvertible
{
	
	/// A textual representation of this instance.
	///
	/// Instead of accessing this property directly, convert an instance of any
	/// type to a string by using the `String(describing:)` initializer. For
	/// example:
	///
	///     struct Point: CustomStringConvertible {
	///         let x: Int, y: Int
	///
	///         var description: String {
	///             return "(\(x), \(y))"
	///         }
	///     }
	///
	///     let p = Point(x: 21, y: 30)
	///     let s = String(describing: p)
	///     print(s)
	///     // Prints "(21, 30)"
	///
	/// The conversion of `p` to a string in the assignment to `s` uses the
	/// `Point` type's `description` property.
	public var description: String
	{
		return (0 ..< height).map
		{
			rowIndex in
			return (0 ..< width)
				.map{self[$0, rowIndex]}
				.map{"\($0)"}
				.joined(separator: "\t")
		}
		.joined(separator: "\n")
	}
	
}


extension Matrix: Equatable
{

	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func ==(lhs: Matrix, rhs: Matrix) -> Bool
	{
		return (lhs.width == rhs.width) &&
			   (lhs.height == rhs.height) &&
			   zip(lhs.values, rhs.values).map(==).reduce(true, {$0 && $1})
	}
	
}
