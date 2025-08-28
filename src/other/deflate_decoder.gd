# GDScript 4.x — DEFLATE-like decompressor (dynamic + fixed Huffman; stored blocks too)
# Probably only works for Abarenbou Princess as this is slightly custom

class_name DeflateDecoder
extends RefCounted

# -----------------------------
# Bit reader (LSB-first in each byte)
# -----------------------------
class BitReader:
	var data: PackedByteArray
	var pos: int = 0
	var bitbuf: int = 0
	var bitcnt: int = 0

	func _init(bytes: PackedByteArray) -> void:
		data = bytes

	func read_bits(n: int) -> int:
		# Ensures at least n bits in buffer; returns value (0..(1<<n)-1), or -1 on EOF
		while bitcnt < n:
			if pos >= data.size():
				push_error("Unexpected EOF while reading bits")
				return -1
			bitbuf |= int(data[pos]) << bitcnt
			pos += 1
			bitcnt += 8
		var val: int = bitbuf & ((1 << n) - 1)
		bitbuf >>= n
		bitcnt -= n
		return val

	func align_to_byte() -> void:
		bitbuf = 0
		bitcnt = 0

# -----------------------------
# Canonical Huffman builder/decoder (LSB-first bit stream)
# -----------------------------
class Huffman:
	var max_len: int = 0
	var table: Dictionary = {} # key = (len << 16) | code_reversed  -> symbol

	static func _reverse_bits(x: int, n: int) -> int:
		var r: int = 0
		for _i in n:
			r = (r << 1) | (x & 1)
			x >>= 1
		return r

	static func build(lengths: Array[int]) -> Huffman:
		var h: Huffman = Huffman.new()
		var count: Array[int] = []
		count.resize(16)
		count.fill(0)
		for l in lengths:
			if typeof(l) == TYPE_INT and l > 0:
				count[l] += 1
				if l > h.max_len:
					h.max_len = l
		var next_code: Array[int] = []
		next_code.resize(16)
		next_code.fill(0)
		var code: int = 0
		for bits in range(1, 16):
			code = (code + count[bits - 1]) << 1
			next_code[bits] = code
		# Assign canonical codes and store reversed (stream is LSB-first)
		for sym in range(lengths.size()):
			var len: int = lengths[sym]
			if len == 0:
				continue
			var c: int = next_code[len]
			next_code[len] += 1
			var key: int = (len << 16) | Huffman._reverse_bits(c, len)
			h.table[key] = sym
		return h

	func decode(br: BitReader) -> int:
		var code: int = 0
		for len in range(1, max_len + 1):
			var b: int = br.read_bits(1)
			if b < 0:
				return -1
			code |= (b << (len - 1))
			var key: int = (len << 16) | code
			if table.has(key):
				return table[key]
		return -1

# -----------------------------
# Public entry point
# -----------------------------
static func decompress(src: PackedByteArray) -> PackedByteArray:
	var br: BitReader = BitReader.new(src)
	var out: PackedByteArray = PackedByteArray()
	var done: bool = false
	while not done:
		# BFINAL (1 bit), BTYPE (2 bits)
		var bfinal: int = br.read_bits(1)
		if bfinal < 0:
			return out
		var btype: int = br.read_bits(2)
		if btype < 0:
			return out
		match btype:
			0:
				# Stored (uncompressed)
				br.align_to_byte()
				var len: int = br.read_bits(16)
				var nlen: int = br.read_bits(16)
				if len < 0 or nlen < 0 or ((len ^ 0xFFFF) & 0xFFFF) != nlen:
					push_error("Stored block LEN/NLEN mismatch")
					return out
				for _i in len:
					var b: int = br.read_bits(8)
					if b < 0:
						return out
					out.append(b)
			1:
				# Fixed Huffman tables
				var litlen_lengths: Array[int] = []
				litlen_lengths.resize(288)
				for i in range(0, 144): litlen_lengths[i] = 8
				for i in range(144, 256): litlen_lengths[i] = 9
				for i in range(256, 280): litlen_lengths[i] = 7
				for i in range(280, 288): litlen_lengths[i] = 8
				var dist_lengths: Array[int] = []
				dist_lengths.resize(32)
				dist_lengths.fill(5)
				var litlen: Huffman = Huffman.build(litlen_lengths)
				var dist: Huffman = Huffman.build(dist_lengths)
				_decode_huffman_stream(br, out, litlen, dist)
			2:
				# Dynamic Huffman — build from headers
				var result: bool = _decode_dynamic_block(br, out)
				if not result:
					return out
			_:
				push_error("Unsupported BTYPE")
				return out
		if bfinal == 1:
			done = true
	return out

# -----------------------------
# Dynamic Huffman parse + decode
# -----------------------------
static func _decode_dynamic_block(br: BitReader, out: PackedByteArray) -> bool:
	var HLIT: int = br.read_bits(5) + 257
	var HDIST: int = br.read_bits(5) + 1
	var HCLEN: int = br.read_bits(4) + 4
	if HLIT < 0 or HDIST < 0 or HCLEN < 0:
		return false
	# Code length alphabet order
	var order: Array[int] = [16,17,18, 0, 8,7,9, 6,10,5,11, 4,12,3,13, 2,14,1,15]
	var clen_lengths: Array[int] = []
	clen_lengths.resize(19)
	clen_lengths.fill(0)
	for i in range(HCLEN):
		var n: int = br.read_bits(3)
		if n < 0: return false
		clen_lengths[ order[i] ] = n
	var clen: Huffman = Huffman.build(clen_lengths)
	# Read lit/len + dist code lengths
	var total: int = HLIT + HDIST
	var lengths: Array[int] = []
	lengths.resize(total)
	lengths.fill(0)
	var i: int = 0
	var prev: int = 0
	while i < total:
		var sym: int = clen.decode(br)
		if sym < 0: return false
		if sym <= 15:
			lengths[i] = sym
			prev = sym
			i += 1
		elif sym == 16:
			var extra: int = br.read_bits(2)
			var repeat: int = 3 + extra
			for _r in repeat:
				if i >= total: return false
				lengths[i] = prev
				i += 1
		elif sym == 17:
			var extra: int = br.read_bits(3)
			var repeat: int = 3 + extra
			for _r in repeat:
				if i >= total: return false
				lengths[i] = 0
				i += 1
		elif sym == 18:
			var extra: int = br.read_bits(7)
			var repeat: int = 11 + extra
			for _r in repeat:
				if i >= total: return false
				lengths[i] = 0
				i += 1
		else:
			push_error("Invalid code-length symbol: %d" % sym)
			return false
	# Split into literal/length and distance trees
	var litlen_lengths: Array[int] = lengths.slice(0, HLIT)
	var dist_lengths: Array[int] = lengths.slice(HLIT, HLIT + HDIST)
	var litlen: Huffman = Huffman.build(litlen_lengths)
	var dist: Huffman = Huffman.build(dist_lengths)
	_decode_huffman_stream(br, out, litlen, dist)
	return true

# -----------------------------
# Decode data using Lit/Len and Dist trees
# -----------------------------
static func _decode_huffman_stream(br: BitReader, out: PackedByteArray, litlen: Huffman, dist: Huffman) -> void:
	# DEFLATE length and distance tables
	var len_base: Array[int] = [3,4,5,6,7,8,9,10, 11,13,15,17, 19,23,27,31, 35,43,51,59, 67,83,99,115, 131,163,195,227, 258]
	var len_extra: Array[int] = [0,0,0,0,0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5, 0]
	var dist_base: Array[int] = [1,2,3,4, 5,7,9,13, 17,25,33,49, 65,97,129,193, 257,385,513,769, 1025,1537,2049,3073, 4097,6145,8193,12289, 16385,24577]
	var dist_extra: Array[int] = [0,0,0,0, 1,1,2,2, 3,3,4,4, 5,5,6,6, 7,7,8,8, 9,9,10,10, 11,11,12,12, 13,13]
	while true:
		var sym: int = litlen.decode(br)
		if sym < 0:
			push_error("Decode error: bad literal/length symbol")
			return
		if sym < 256:
			out.append(sym)
			continue
		elif sym == 256:
			# end of block
			return
		else:
			var idx: int = sym - 257
			if idx < 0 or idx >= len_base.size():
				push_error("Invalid length symbol: %d" % sym)
				return
			var length: int = len_base[idx]
			var eb: int = len_extra[idx]
			if eb > 0:
				var add: int = br.read_bits(eb)
				if add < 0: return
				length += add
			var dsym: int = dist.decode(br)
			if dsym < 0 or dsym >= dist_base.size():
				push_error("Invalid distance symbol: %d" % dsym)
				return
			var distance: int = dist_base[dsym]
			var deb: int = dist_extra[dsym]
			if deb > 0:
				var dadd: int = br.read_bits(deb)
				if dadd < 0: return
				distance += dadd
			# Copy from output (LZ77 back-reference)
			var out_len: int = out.size()
			if distance <= 0 or distance > out_len:
				push_error("Invalid back-reference distance: %d" % distance)
				return
			for _i in length:
				var b: int = out[out_len - distance]
				out.append(b)
				out_len += 1
