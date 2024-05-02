module StippleTypedArrays

using Base64

const BASE64ENCODING = Ref(false)

using Stipple

export TypedArray

type_dict = LittleDict(
    UInt8 => "Uint8Array",
    UInt16 => "Uint16Array",
    UInt32 => "Uint32Array",
    Int8 => "Int8Array",
    Int16 => "Int16Array",
    Int32 => "Int32Array",
    Float32 => "Float32Array",
    Float64 => "Float64Array",
    Int64 => "BigInt64Array",
    UInt64 => "BigUint64Array",
)

struct TypedArray{T}
    array::Vector{T}
end

Base.setindex!(x::TypedArray, args...) = Base.setindex!(x.array, args...)
Base.getindex(x::TypedArray, args...) = Base.getindex(x.array, args...)
Base.push!(x::TypedArray, args...) = Base.push!(x.array, args...)
Base.pushfirst!(x::TypedArray, args...) = Base.pushfirst!(x.array, args...)
Base.pop!(x::TypedArray, args...) = Base.pop!(x.array, args...)
Base.popfirst!(x::TypedArray, args...) = Base.popfirst!(x.array, args...)
Base.popat!(x::TypedArray, args...) = Base.pop!(x.array, args...)

Base.convert(::Type{TypedArray}, v::AbstractVector{T}) where T = TypedArray{T}(convert(Vector{T}, v))
Base.convert(::Type{T}, ta::TypedArray) where T <: Union{AbstractVector, TypedArray}  = convert(T, BASE64ENCODING[] ? base64encode(ta.array) : ta.array)
Base.convert(::Type{TypedArray{T1}}, v::AbstractVector{T2}) where {T1, T2} = TypedArray{T1}(convert(Vector{T1}, v))

Stipple.render(ta::TypedArray{T}) where T = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : ta.array)
Stipple.render(ta::TypedArray{T}) where T <: Int64 = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : string.(ta.array))
Stipple.render(ta::TypedArray{T}) where T <: UInt64 = LittleDict(:typedArray => T, :array => BASE64ENCODING[] ? base64encode(ta.array) : string.(reinterpret(Int64, ta.array)))

Stipple.jsrender(ta::TypedArray{T}, args...) where T <: Real = JSONText("$(type_dict[T]).from($(json(BASE64ENCODING[] ? base64encode(ta.array) : ta.array)))")
Stipple.jsrender(ta::TypedArray{T}, args...) where T <: UInt64 = JSONText("$(type_dict[T]).from($(json(BASE64ENCODING[] ? base64encode(ta.array) : string.(ta.array))))")
Stipple.jsrender(ta::TypedArray{T}, args...) where T <: Int64 = JSONText("$(type_dict[T]).from($(json(BASE64ENCODING[] ? base64encode(ta.array) : string.(ta.array))))")
 
Stipple.stipple_parse(::Type{TypedArray{T}}, v::Vector) where T = TypedArray(Vector{T}(v))

Stipple.stipple_parse(T::Type{TypedArray{UInt64}}, v::Vector) = Stipple.stipple_parse(T, [v...])
Stipple.stipple_parse(::Type{TypedArray{UInt64}}, v::Vector{String}) = TypedArray(parse.(UInt64, v))
Stipple.stipple_parse(::Type{TypedArray{UInt64}}, v::Vector{T}) where T <: Number = TypedArray(Vector{UInt64}(v))

Stipple.stipple_parse(T::Type{TypedArray{Int64}}, v::Vector) = Stipple.stipple_parse(T, [v...])
Stipple.stipple_parse(::Type{TypedArray{Int64}}, v::Vector{String}) = TypedArray(parse.(Int64, v))
Stipple.stipple_parse(::Type{TypedArray{Int64}}, v::Vector{T}) where T <: Number = TypedArray(Vector{UInt64}(v))


js_revive_typedArray = """
    function (k, v) {
        if ( (typeof v==='object') && (v!=null) && (v.typedArray) ) {
            const array = (typeof v.array === 'string') ? base64ToArrayBuffer(v.array) : v.array
            switch (v.typedArray) {
                case 'UInt8':   a = new Uint8Array(array); break
                case 'UInt16':  a = new Uint16Array(array); break
                case 'UInt32':  a = new Uint32Array(array); break
                case 'UInt64':  a = new BigUint64Array(array.map(BigInt)); break
                case 'Int8':    a = new Int8Array(array); break
                case 'Int16':   a = new Int16Array(array); break
                case 'Int32':   a = new Int32Array(array); break
                case 'Int64':   a = new BigInt64Array(array.map(BigInt)); break
                case 'Float32': a = new Float32Array(array); break
                case 'Float64': a = new Float64Array(array); break
                default: a = array
            }
            return a
        } else {
            return v
        }
    }
"""


function deps()
    [
        script(
            "\n",
            [
                "    $atype.prototype['toJSON'] = function () { return $(startswith(atype, "Big") ? "this.toString().split(',')" : "Array.from(this)") };\n"
                for atype in values(type_dict)
            ],
            [
                """
                BigInt.prototype['toJSON'] = function () { return this.toString() }
                
                function base64ToArrayBuffer(base64) {
                    var binaryString = atob(base64);
                    var bytes = new Uint8Array(binaryString.length);
                    for (var i = 0; i < binaryString.length; i++) {
                        bytes[i] = binaryString.charCodeAt(i);
                    }
                    return bytes.buffer;
                }
                """
            ]
        )
        script(Stipple.js_add_reviver(js_revive_typedArray))
    ]
end

end # module StippleTypedArrays
