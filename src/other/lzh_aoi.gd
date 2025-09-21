#NOTE: NOT WORKING. From Aoi Sora no Neosphere - Nanoca Flanka Hatsumei Koubouki 2 from function 0x00187040

# Example usage:
#var f: FileAccess = FileAccess.open("path/test.rlh", FileAccess.READ)
#var o: FileAccess = FileAccess.open("path/test.dec", FileAccess.WRITE)
#var decompressor = LZHuffmanDecompressor.new()
#decompressor.set_active(true)
#
#var compressed_data: PackedByteArray = f.get_buffer(f.get_length())
#f.close()
#
#var decompressed: PackedByteArray = decompressor.decompress(compressed_data.slice(4), compressed_data.decode_u32(0))
#o.store_buffer(decompressed)

class_name LZHuffmanDecompressor
extends RefCounted

# Constants
const CIRCULAR_BUFFER_SIZE = 0x1000
const CIRCULAR_BUFFER_MASK = 0xFFF
const SPACE_FILL_SIZE = 0xFC0
const REBALANCE_THRESHOLD = 0x8000
const MAX_SYMBOLS = 0x273

# Global state variables
var global_active_flag: int = 0
var global_output_count: int = 0
var global_last_symbol: int = 0xFFFF
var global_bit_accumulator: int = 0
var global_buffer_pos: int = 0
var max_output_count: int = 0

# Bit stream processing
var bit_count: int = 0
var bit_buffer: int = 0
var input_data: PackedByteArray
var input_position: int = 0

# Circular buffer for LZ77
var circular_buffer: PackedByteArray
var buffer_write_pos: int = 0xFC0

# Output
var output_buffer: PackedByteArray
var output_count: int = 0

# Huffman/Symbol tables
var symbol_table1: PackedInt32Array  # Frequency counts
var symbol_table2: PackedInt32Array  # Symbol mappings
var symbol_table3: PackedInt32Array  # Parent/child relationships
var frequency_table: PackedInt32Array
var parent_table: PackedInt32Array
var lookup_table1: PackedInt32Array
var lookup_table2: PackedInt32Array

# Run-length encoding state
var repeat_count: int = 0
var current_accumulator: int = 0
var last_output_byte: int = 0xFFFF

# Lookup tables for bit operations
var bit_length_table: PackedByteArray
var bit_mask_table: PackedInt32Array
var shift_table: PackedInt32Array

func _init():
	initialize_tables()

func initialize_tables():
	"""Initialize all lookup tables and data structures"""
	# Initialize arrays
	symbol_table1 = PackedInt32Array()  # Will be loaded from 01D85830.bin
	symbol_table2 = PackedInt32Array()  # Will be loaded from 01D83F50.bin  
	symbol_table3 = PackedInt32Array()  # Will be loaded from 01D84940.bin
	frequency_table = PackedInt32Array()
	parent_table = PackedInt32Array()
	lookup_table1 = PackedInt32Array()
	lookup_table2 = PackedInt32Array()
	
	# Load tables from files - these contain the actual Huffman tree structure
	load_table_from_file("res://src/other/tables/01D85830_aoi.bin", symbol_table1)
	load_table_from_file("res://src/other/tables/01D83F50_aoi.bin", symbol_table2) 
	load_table_from_file("res://src/other/tables/01D84940_aoi.bin", symbol_table3)
	
	# Initialize other arrays
	frequency_table.resize(MAX_SYMBOLS)
	parent_table.resize(MAX_SYMBOLS)
	lookup_table1.resize(MAX_SYMBOLS)
	lookup_table2.resize(MAX_SYMBOLS)
	
	# Initialize bit manipulation tables
	bit_length_table = PackedByteArray()
	bit_mask_table = PackedInt32Array()
	shift_table = PackedInt32Array()
	
	bit_length_table.resize(256)
	bit_mask_table.resize(64)
	shift_table.resize(64)
	
	# Initialize frequency tables (start with equal frequencies)
	for i in range(frequency_table.size()):
		frequency_table[i] = 1
		if i < lookup_table1.size():
			lookup_table1[i] = 1
		if i < lookup_table2.size():
			lookup_table2[i] = 1
	
	# Initialize circular buffer
	circular_buffer = PackedByteArray()
	circular_buffer.resize(CIRCULAR_BUFFER_SIZE)
	circular_buffer.fill(0x20)  # Fill with spaces

func load_table_from_file(file_path: String, target_array: PackedInt32Array):
	"""Load binary table data from file and convert to int32 array"""
	if not FileAccess.file_exists(file_path):
		push_error("Table file not found: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open table file: " + file_path)
		return
	
	var file_size = file.get_length()
	var byte_data = file.get_buffer(file_size)
	file.close()
	
	# Convert bytes to int32 array (assuming little-endian 32-bit integers)
	var int_count = file_size / 4
	target_array.resize(int_count)
	
	for i in range(int_count):
		var byte_offset = i * 4
		if byte_offset + 3 < byte_data.size():
			var value = (byte_data[byte_offset]) | \
						(byte_data[byte_offset + 1] << 8) | \
						(byte_data[byte_offset + 2] << 16) | \
						(byte_data[byte_offset + 3] << 24)
			target_array[i] = value

# Alternative constructor that takes table data directly
func initialize_with_table_data(table1_data: PackedByteArray, table2_data: PackedByteArray, table3_data: PackedByteArray):
	"""Initialize with raw table data instead of loading from files"""
	symbol_table1 = PackedInt32Array()
	symbol_table2 = PackedInt32Array()
	symbol_table3 = PackedInt32Array()
	
	# Convert byte arrays to int32 arrays
	convert_bytes_to_int32_array(table1_data, symbol_table1)
	convert_bytes_to_int32_array(table2_data, symbol_table2)
	convert_bytes_to_int32_array(table3_data, symbol_table3)
	
	# Initialize other structures
	frequency_table = PackedInt32Array()
	parent_table = PackedInt32Array()
	lookup_table1 = PackedInt32Array()
	lookup_table2 = PackedInt32Array()
	
	frequency_table.resize(MAX_SYMBOLS)
	parent_table.resize(MAX_SYMBOLS)
	lookup_table1.resize(MAX_SYMBOLS)
	lookup_table2.resize(MAX_SYMBOLS)
	
	# Initialize with default values
	for i in range(frequency_table.size()):
		frequency_table[i] = 1
		if i < lookup_table1.size():
			lookup_table1[i] = 1
		if i < lookup_table2.size():
			lookup_table2[i] = 1
	
	# Initialize circular buffer
	circular_buffer = PackedByteArray()
	circular_buffer.resize(CIRCULAR_BUFFER_SIZE)
	circular_buffer.fill(0x20)

func convert_bytes_to_int32_array(byte_data: PackedByteArray, target_array: PackedInt32Array):
	"""Convert raw bytes to int32 array - handle both byte and word access"""
	# The original MIPS code accesses these tables as both bytes and 32-bit words
	# For now, let's store them as bytes and provide word access when needed
	var int_count = (byte_data.size() + 3) / 4  # Round up to handle partial words
	target_array.resize(int_count)
	
	for i in range(int_count):
		var byte_offset = i * 4
		var value = 0
		
		# Read up to 4 bytes, handling partial reads at end
		for j in range(4):
			if byte_offset + j < byte_data.size():
				value |= (byte_data[byte_offset + j] << (j * 8))
		
		target_array[i] = value

# Add helper function to access tables as bytes when needed
func get_table_byte(table: PackedInt32Array, byte_offset: int) -> int:
	"""Get a single byte from an int32 table"""
	var word_index = byte_offset / 4
	var byte_index = byte_offset % 4
	
	if word_index >= table.size():
		return 0
		
	var word_value = table[word_index]
	return (word_value >> (byte_index * 8)) & 0xFF

func get_table_word(table: PackedInt32Array, word_offset: int) -> int:
	"""Get a 32-bit word from table"""
	if word_offset >= table.size():
		return 0
	return table[word_offset]

func decompress(input: PackedByteArray, max_output: int) -> PackedByteArray:
	"""Main decompression function"""
	if global_active_flag == 0:
		return PackedByteArray()
	
	# Initialize state
	input_data = input
	input_position = 0
	max_output_count = max_output
	global_output_count = 0
	output_count = 0
	buffer_write_pos = SPACE_FILL_SIZE
	
	# Initialize output buffer
	output_buffer = PackedByteArray()
	output_buffer.resize(max_output)
	
	# Reset decompression state
	global_last_symbol = 0xFFFF
	global_bit_accumulator = 0
	global_buffer_pos = 0
	bit_count = 0
	bit_buffer = 0
	repeat_count = 0
	current_accumulator = 0
	last_output_byte = 0xFFFF
	
	# Main decompression loop
	while global_output_count < max_output_count:
		# Read Huffman-encoded symbol
		var symbol = read_huffman_symbol()
		if symbol == -1:  # End of input
			break
		
		# Process symbol through mapping
		symbol = process_symbol(symbol - 0x27B)
		symbol -= 0x27B
		
		if symbol < 0x100:
			# Direct literal byte
			output_byte(symbol)
			circular_buffer[buffer_write_pos & CIRCULAR_BUFFER_MASK] = symbol
			buffer_write_pos = (buffer_write_pos + 1) & CIRCULAR_BUFFER_MASK
		else:
			# LZ77 back-reference
			var match_info = read_match_info()
			var distance = extract_distance(match_info)
			var length = extract_length(symbol - 0x100 + 3)
			
			# Copy from circular buffer
			for i in range(length):
				var back_pos = (buffer_write_pos - distance + i) & CIRCULAR_BUFFER_MASK
				var data = circular_buffer[back_pos]
				output_byte(data)
				circular_buffer[buffer_write_pos & CIRCULAR_BUFFER_MASK] = data
				buffer_write_pos = (buffer_write_pos + 1) & CIRCULAR_BUFFER_MASK
	
	# Return the actual output
	output_buffer.resize(output_count)
	return output_buffer

func read_huffman_symbol() -> int:
	"""Read a Huffman-encoded symbol from the bit stream"""
	# Based on MIPS code analysis:
	# 1. Gets initial symbol from a table lookup (around address 0x4938 offset)
	# 2. Loops while symbol < 0x27B 
	# 3. Each iteration: reads a bit, adds to symbol, looks up in symbol_table2
	
	# The initial symbol comes from some table - let's use a reasonable default
	# In the MIPS code, this comes from lw s1, $4938(v0) 
	var current_symbol = 0  # Start from root of tree
	
	# Continue until we reach a terminal symbol (>= 0x27B)
	while current_symbol < 0x27B:
		# Check bit count and refill if needed
		if bit_count < 9:
			fill_bit_buffer()
		
		if bit_count <= 0:
			return -1
		
		# Read next bit - MIPS code does complex bit manipulation
		# It shifts a global accumulator and tests the high bit
		var navigation_bit = (bit_buffer >> 15) & 1
		bit_buffer = (bit_buffer << 1) & 0xFFFF
		bit_count -= 1
		
		# The key insight: current_symbol + bit gives the index into the tree table
		# This is what the MIPS code does: addu v0, s1, v0 (symbol + bit)
		var tree_index = current_symbol + navigation_bit
		
		# Look up next symbol in the tree table (symbol_table2 = 01D83F50)
		# Original MIPS: sll v0, v0, 2 then lw from table
		if tree_index >= 0 and tree_index < symbol_table2.size():
			current_symbol = get_table_word(symbol_table2, tree_index)
		else:
			# Try byte-level access if word access fails
			var byte_lookup = tree_index * 4
			if byte_lookup < symbol_table2.size() * 4:
				current_symbol = get_table_word(symbol_table2, tree_index)
			else:
				return -1
		
		# Bounds check to prevent infinite loops
		if current_symbol < 0 or current_symbol > 0x10000:
			return -1
	
	return current_symbol

func fill_bit_buffer():
	"""Fill the bit buffer from input stream"""
	while bit_count < 8 and input_position < input_data.size():
		var byte_val = input_data[input_position]
		input_position += 1
		
		# Handle signed/unsigned conversion
		if byte_val >= 128:
			byte_val = 0  # Treat as 0 for negative values (as in original)
		
		var shift_amount = 8 - bit_count
		bit_buffer |= (byte_val << shift_amount)
		bit_count += 8

func read_match_info() -> int:
	"""Read match information for LZ77 back-references"""
	if bit_count < 9:
		fill_bit_buffer()
	
	# Extract match info from bit stream
	var info = (bit_buffer >> 8) & 0xFF
	bit_buffer = (bit_buffer << 8) & 0xFFFF
	bit_count -= 8
	
	# Decode using lookup tables
	var high_bits = (info >> 4) & 0xF
	var low_bits = info & 0xF
	
	# Use lookup tables for decoding (simplified)
	var decoded_info = (high_bits << 6) | low_bits
	
	return decoded_info

func extract_distance(match_info: int) -> int:
	"""Extract distance from match info"""
	return (match_info & 0x3F) + 1

func extract_length(length_code: int) -> int:
	"""Extract length from length code"""
	return length_code + 3

func process_symbol(symbol: int) -> int:
	"""Process symbol and update adaptive Huffman tree"""
	# Check if rebalancing is needed
	if global_bit_accumulator == REBALANCE_THRESHOLD:
		rebalance_trees()
	
	var current = symbol
	
	# Update frequency and rebalance tree
	while current != 0:
		# Increment frequency
		if current < frequency_table.size():
			frequency_table[current] += 1
		
		# Find insertion point
		var insert_pos = current + 1
		while insert_pos < frequency_table.size() and frequency_table[insert_pos] < frequency_table[current]:
			insert_pos += 1
		insert_pos -= 2
		
		# Swap if necessary
		if insert_pos != current and insert_pos >= 0 and insert_pos < frequency_table.size():
			swap_tree_nodes(current, insert_pos)
			current = insert_pos
		
		# Move up tree
		if current < parent_table.size():
			current = parent_table[current]
		else:
			break
	
	return symbol

func swap_tree_nodes(node1: int, node2: int):
	"""Swap two nodes in the Huffman tree"""
	if node1 >= frequency_table.size() or node2 >= frequency_table.size():
		return
	
	# Swap frequencies
	var temp = frequency_table[node1]
	frequency_table[node1] = frequency_table[node2]
	frequency_table[node2] = temp
	
	# Update symbol mappings if available
	if node1 < symbol_table2.size() and node2 < symbol_table2.size():
		temp = symbol_table2[node1]
		symbol_table2[node1] = symbol_table2[node2]
		symbol_table2[node2] = temp

func rebalance_trees():
	"""Rebalance the Huffman trees when threshold is reached"""
	# Halve all frequencies to prevent overflow
	for i in range(frequency_table.size()):
		frequency_table[i] = frequency_table[i] >> 1
	
	global_bit_accumulator = 0

func output_byte(byte_value: int):
	"""Handle byte output with run-length encoding"""
	if repeat_count > 0:
		# Handle run-length encoding
		repeat_count -= 1
		var masked_byte = byte_value & 0x7F
		var is_repeat = (byte_value & 0x80) != 0
		
		# Calculate run length
		var run_length = (repeat_count << 3) - repeat_count  # 7 * repeat_count
		var total_output = current_accumulator + (masked_byte << run_length)
		current_accumulator = total_output
		
		if not is_repeat:
			# Output accumulated bytes
			repeat_count = 0
			while total_output > 0 and output_count < output_buffer.size():
				if last_output_byte < 0x100:
					output_buffer[output_count] = last_output_byte
					output_count += 1
					global_output_count += 1
				total_output -= 1
			last_output_byte = 0xFFFF
		else:
			repeat_count += 1
	else:
		# Normal byte output
		if last_output_byte >= 0x100:  # First byte or reset
			last_output_byte = byte_value
			repeat_count = 0
		else:
			if last_output_byte == byte_value:
				# Start run-length sequence
				current_accumulator = 0
				repeat_count = 1
			else:
				# Output single byte
				if output_count < output_buffer.size():
					output_buffer[output_count] = last_output_byte
					output_count += 1
					global_output_count += 1
			last_output_byte = byte_value

func set_active(active: bool):
	"""Enable/disable decompression"""
	global_active_flag = 1 if active else 0
