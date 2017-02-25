//
//  MatrixCore.swift
//  NeuralKit
//
//  Created by Palle Klewitz on 19.02.17.
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
	var values: [Float]
	
	/// Width of the matrix
	/// If the width is zero, the matrix is empty for any height
	let width: Int
	
	
	/// Height of the matrix
	/// If the height is zero, the matrix is empty for any width
	let height: Int
	
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
		
		// The following line crashes the compiler when using Swift 3.0
//		assert(rows.reduce(true, {$0 && $1.count == self.width}), "The length of all rows must be equal")
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
		var result = [Float](repeating: 0, count: lhs.height)
		cblas_sgemv(CblasRowMajor, CblasNoTrans, Int32(lhs.height), Int32(lhs.width), 1.0, lhs.values, Int32(lhs.width), rhs, 1, 1.0, &result, 1)
		return result
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
			return values[width * y + x]
		}
		
		set (new)
		{
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
			var result = [Float](repeating: 0, count: width * height)
			for y in 0 ..< height
			{
				for x in 0 ..< width
				{
					result[width * y + x] = values[self.width * (row + y) + column + x]
				}
			}
			return Matrix(values: result, width: width, height: height)
		}
		
		set (new)
		{
			for y in 0 ..< height
			{
				for x in 0 ..< width
				{
					values[self.width * (row + y) + column + x] = new.values[width * y + x]
				}
			}
		}
	}
	
	
	/// The transposed matrix generated by swapping all fields (i,j) with (j,i).
	public var transposed: Matrix
	{
		var result = [Float](repeating: 0, count: width * height)
		vDSP_mtrans(self.values, 1, &result, 1, vDSP_Length(width), vDSP_Length(height))
		return Matrix(values: result, width: height, height: width)
	}
	
	
	/// Performs a convolution.
	/// Every element of the matrix will be multiplied with the
	/// Element at the same position as the other matrix.
	/// The matrix of products will then be summed together.
	///
	/// If both matrices have a size of 1 for all but one dimension
	/// the result of this operation will be equal to a dot product.
	///
	/// - Parameter other: Other matrix to convolve with the matrix
	/// - Returns: Sum of matrix generated by multiplying values of the matrix with 
	/// values of the other matrix at equal positions
	public func convolve(with other: Matrix) -> Float
	{
		return self.values * other.values
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
	
}

/// A 3 dimensional matrix (tensor)
public struct Matrix3
{
	
	/// Values stored in the matrix.
	/// The element at position column: n, row: m, slice: l will be at n + width * m + height * width * l
	var values: [Float]
	
	
	/// Width of the tensor
	let width: Int
	
	
	/// Height of the tensor
	let height: Int
	
	
	/// Depth of the tensor
	let depth: Int
	
	
	/// Dimension of the tensor
	public var dimension:(width: Int, height: Int, depth: Int)
	{
		return (width: width, height: height, depth: depth)
	}
	
	
	/// Indices of the tensor in the form (column,row,slice)
	///
	/// This can be used to avoid nested loops on index based iteration:
	///
	///		for (column, row, slice) in matrix.indices {
	///			let value = matrix[column, row, slice]
	///			...
	///		}
	///
	/// The number of possible indices is equal to width * height * depth of the matrix
	public var indices:[(Int,Int,Int)]
	{
		func combine<BoundA: Comparable, BoundB: Comparable, BoundC: Comparable>(_ a: CountableRange<BoundA>, _ b: CountableRange<BoundB>, _ c: CountableRange<BoundC>) -> [(BoundA,BoundB,BoundC)]
		{
			return c.flatMap{elC in b.flatMap{elB in a.map{($0,elB,elC)}}}
		}
		return combine(0..<width,0..<height,0..<depth)
	}
	
	
	/// Initializes a three dimensional matrix from the given values and dimensions
	///
	/// The number of values must be equal to width * height * depth
	///
	/// The element at position column: n, row: m, slice: l must be at n + width * m + height * width * l
	/// in the provided value vector.
	///
	/// - Parameters:
	///   - values: Values which will be stored in the matrix
	///   - width: Width of the matrix
	///   - height: Height of the matrix
	///   - depth: Depth of the matrix
	public init(values: [Float], width: Int, height: Int, depth: Int)
	{
		precondition(width * height * depth == values.count, "Matrix dimensions are incorrect")
		self.values = values
		self.width = width
		self.height = height
		self.depth = depth
	}
	
	
	/// Initializes a three dimensional matrix from a vector of slices.
	///
	/// The slices must be vectors containing vectors of columns of the matrix
	///
	/// - Parameter values: Slices from which the matrix will be initialized
	public init(values: [[[Float]]])
	{
		self.values = values.flatMap{$0.flatMap{$0}}
		self.width = values.first?.first?.count ?? 0
		self.height = values.first?.count ?? 0
		self.depth = values.count
		assert(self.values.count == self.width * self.height * self.depth, "Dimension of matrix does not match number of elements provided.")
	}
	
	
	/// Initializes a three dimensional matrix and sets every value to the repeating value.
	///
	/// - Parameters:
	///   - value: Value to which every element of the matrix will be set
	///   - width: Width of the matrix
	///   - height: Height of the matrix
	///   - depth: Depth of the matrix
	public init(repeating value: Float, width: Int, height: Int, depth: Int)
	{
		self.values = [Float](repeating: value, count: width * height * depth)
		self.width = width
		self.height = height
		self.depth = depth
	}
	
	
	/// Subscript to retrieve or set a single element of the matrix
	///
	/// - Parameters:
	///   - x: Column of the element
	///   - y: Row of the element
	///   - z: Slice of the element
	public subscript(x: Int, y: Int, z: Int) -> Float
	{
		get
		{
			return values[width * (height * z + y) + x]
		}
		
		set (new)
		{
			values[width * (height * z + y) + x] = new
		}
	}
	
	
	/// Subscript to retrieve or set a three dimensional submatrix of the matrix
	///
	/// If the position of elements from the submatrix exceeds the bounds of the matrix,
	/// the element will be set to zero on retrieval or ignored when copied into the matrix.
	///
	/// - Parameters:
	///   - column: Column at which the submatrix starts
	///   - row: Row at which the submatrix starts
	///   - slice: Slice at which the submatrix starts
	///   - width: Width of the submatrix
	///   - height: Height of the submatrix
	///   - depth: Depth of the submatrix
	public subscript(x column: Int, y row: Int, z slice: Int, width width: Int, height height: Int, depth depth: Int) -> Matrix3
	{
		get
		{
			var result = Matrix3(repeating: 0, width: width, height: height, depth: depth)
			for (x,y,z) in result.indices
				where 0 ..< self.depth ~= z + slice && 0 ..< self.height ~= y + row && 0 ..< self.width ~= x + column
			{
				result[x,y,z] = self[x+column, y+row, z+slice]
			}
			return result
		}
		
		set (new)
		{
			for (x,y,z) in new.indices
				where 0 ..< self.depth ~= z + slice && 0 ..< self.height ~= y + row && 0 ..< self.width ~= x + column
			{
				values[self.width * (self.height * (slice + z) + row + y) + column + x] = new.values[width * (height * z + y) + x]
			}
		}
	}
	
	
	/// Performs a convolution.
	/// Every element of the matrix will be multiplied with the
	/// Element at the same position as the other matrix.
	/// The matrix of products will then be summed together.
	/// 
	/// If both matrices have a size of 1 for all but one dimension
	/// the result of this operation will be equal to a dot product.
	///
	/// - Parameter other: Other matrix to convolve with the matrix
	/// - Returns: Sum of matrix generated by multiplying values of the matrix with
	/// values of the other matrix at equal positions
	public func convolve(with other: Matrix3) -> Float
	{
		return self.values * other.values
	}
	
	
	/// Reverses the matrix. The element at position (i,j,k) will be at (width-i,height-j,depth-k)
	/// in the resulting matrix.
	///
	/// - Returns: Matrix generated by reversing a matrix.
	public func reversed() -> Matrix3
	{
		return Matrix3(values: self.values.reversed(), width: self.width, height: self.height, depth: self.depth)
	}
	
	
	/// Returns a matrix generated from a matrix by applying the transform function to every element
	///
	/// - Parameter transform: Transform function which will be applied on every element
	/// - Returns: Matrix generated by applying the transform function to the elements of the initial matrix
	public func map(_ transform: (Float) throws -> Float) rethrows -> Matrix3
	{
		return try Matrix3(values: self.values.map(transform), width: self.width, height: self.height, depth: self.depth)
	}
	
	
	/// Returns a matrix generated from a matrix by applying the vectorized transform function to every element
	///
	/// - Parameter transform: Vectorized transform function which will be applied on every element
	/// - Returns: Matrix generated by applying the transform function to the elements of the initial matrix
	public func mapv(_ transform: ([Float]) throws -> [Float]) rethrows -> Matrix3
	{
		return try Matrix3(values: transform(self.values), width: width, height: height, depth: depth)
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

extension Matrix3: CustomStringConvertible
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
		return (0 ..< depth).map
		{
			zIndex in
			return (0 ..< height).map
			{
				rowIndex in
				return (0 ..< width)
					.map{self[$0, rowIndex, zIndex]}
					.map{"\($0)"}
					.joined(separator: "\t")
			}
			.joined(separator: "\n")
		}
		.joined(separator: "\n\n")
	}
	
}

