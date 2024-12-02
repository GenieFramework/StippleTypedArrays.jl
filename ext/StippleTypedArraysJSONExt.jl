module StippleTypedArraysJSONExt

using Stipple.OrderedCollections
using StippleTypedArrays
using JSON

import StippleTypedArrays: BASE64ENCODING, base64encode

JSON.lower(ta::TypedArray{T}) where T = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : ta.array)
JSON.lower(ta::TypedArray{T}) where T <: Int64 = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : string.(ta.array))
JSON.lower(ta::TypedArray{T}) where T <: UInt64 = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : string.(reinterpret(Int64, ta.array)))

end