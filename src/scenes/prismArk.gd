extends Control

@onready var file_load_dat: FileDialog = $FILELoadDAT
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path:String
var selected_files: PackedStringArray
var chose_files: bool = false
var chose_folder: bool = false
var remove_alpha: bool = false


#func _ready() -> void:
	#var buff: PackedByteArray
	#var in_file: FileAccess
	#var out_file: FileAccess
	#var buff2: PackedByteArray
	#
	#in_file = FileAccess.open("F:/Games/Notes/Prism Ark/a.zzz", FileAccess.READ)
	#out_file = FileAccess.open("F:/Games/Notes/Prism Ark/a.DEC", FileAccess.WRITE)
	#buff = decompress_rle2(in_file.get_buffer(in_file.get_length()), 0x047F70)
	#out_file.store_buffer(buff)


func _process(_delta: float) -> void:
	if chose_files and chose_folder:
		extractDat()
		selected_files.clear()
		chose_files = false
		chose_folder = false


func extractDat() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var arc_name: String
	var arc_size: int
	var num_files: int
	var off_tbl: int
	var name_tbl: int
	var f_offset: int
	var f_name: String
	var name_size: int
	var f_size: int
	var f_ext: String
	var ext: String
	var tga_header: PackedByteArray
	var tga_img: PackedByteArray
	var swap: PackedByteArray
	var width: int
	var height: int
	var bpp: int
	var pal: PackedByteArray
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		arc_name = selected_files[i].get_file()
		#f_ext = selected_files[i].get_extension()
		
		in_file.seek(8)
		off_tbl = in_file.get_32() + 0x20
		
		in_file.seek(off_tbl - 0xC)
		arc_size = in_file.get_32()
		num_files = in_file.get_32()
		
		for files in range(num_files):
			in_file.seek((files * 8) + off_tbl)
			
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			var bytes: int = buff.decode_u32(0)
			if bytes == 0x005A5A5A: # ZZZ
				ext = ".ZZZ"
			elif bytes == 0x00474150: # PAG
				ext = ".PAG"
			elif bytes == 0x00475850: # PXG
				ext = ".PXG"
			elif bytes == 0x324D4954: # TIM2
				ext = ".TM2"
			elif bytes == 0x00584554: # TEX
				ext = ".TEX"
				f_name = "%08d%s" % [files, ext]
				
				bpp = buff.decode_u32(0x8)
				width = buff.decode_u32(0x2C)
				height = buff.decode_u32(0x30)
				
				tga_header = ComFuncs.makeTGAHeader(true, 1, 32, bpp, width, height)
				if bpp == 8:
					pal = ComFuncs.unswizzle_palette(buff.slice(0x80, 0x480), 32)
					tga_img = buff.slice(0x480)
				elif bpp == 32:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					print("0x%08X 0x%08X %s/%s" % [f_offset, f_size, folder_path, f_name])
					
					ext = ".PNG"
					f_name = "%08d%s" % [files, ext]
					buff = buff.slice(0x80)
					
					if remove_alpha:
						for j in range(0, buff.size(), 4):
							buff.encode_u8(j + 3, 0xFF)
							
					var png: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
					png.save_png(folder_path + "/%s" % f_name)
					continue
				#elif bpp == 4:
					#pal = ComFuncs.unswizzle_palette(buff.slice(0x80, 0xC0), 4)
					#tga_img = buff.slice(0xC0)
				else:
					push_error("Unsupported BPP %02d in %s!" % [bpp, f_name])
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				
					print("0x%08X 0x%08X %s/%s" % [f_offset, f_size, folder_path, f_name])
					continue
					
				swap.resize(4)
				for j in range(0, pal.size(), 4):
					swap[0] = pal.decode_u8(j)
					swap[1] = pal.decode_u8(j + 1)
					swap[2] = pal.decode_u8(j + 2)
					pal.encode_u8(j, swap[2])
					pal.encode_u8(j + 1, swap[1])
					pal.encode_u8(j + 2, swap[0])
					
				tga_header.append_array(pal)
				tga_header.append_array(tga_img)
				
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				print("0x%08X 0x%08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				ext = ".TGA"
				f_name = "%08d%s" % [files, ext]
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(tga_header)
				continue
			else:
				ext = ".BIN"
			
			if (arc_name == "PA_CG.DAT" or arc_name == "PA_VOI.DAT" or arc_name == "PA_BGM.DAT" or arc_name == "PA_SE.DAT" or arc_name == "PA_BTL.DAT") and files == num_files - 1:
				f_name = "names.bin"
			else:
				if arc_name == "PA_BGM.DAT":
					ext = ".ADX"
				if arc_name == "PA_MOV.DAT":
					ext = ".SFD"
				f_name = "%08d%s" % [files, ext]
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			
			print("0x%08X 0x%08X %s/%s" % [f_offset, f_size, folder_path, f_name])
	
	print_rich("[color=green]Finished![/color]")

func decompress_rle_like_keep(input: PackedByteArray, decompressed_size: int) -> PackedByteArray:
	var output = PackedByteArray()
	output.resize(decompressed_size)  # Preallocate the output buffer
	var idx = 0  # Input pointer
	var output_pos = 0  # Current position in the output buffer

	while idx < input.size():
		var control = input[idx]  # Read the control byte
		idx += 1

		if (control & 0xC0) == 0x00:
			# Literal copy
			if output_pos < decompressed_size:
				output.encode_u8(output_pos, control)
				output_pos += 1

		elif (control & 0xC0) == 0x40:
			# Offset copy
			if idx + 1 >= input.size():
				break  # Prevent out-of-bounds
			var offset = ((control & 0x0F) << 8) | input[idx]
			idx += 1
			var length = ((control & 0x30) >> 4) + 3
			for a in range(length):
				if output_pos - offset < 0 or output_pos >= decompressed_size:
					print("Warning: Offset out of bounds during offset copy.")
					break
				var value = output.decode_u8(output_pos - offset)
				output.encode_u8(output_pos, value)
				output_pos += 1

		elif (control & 0xC0) == 0x80:
			# Small offset copy
			var offset = (control & 0x0F) + 3
			var length = ((control >> 4) & 0x03) + 3
			for a in range(length):
				if output_pos - offset < 0 or output_pos >= decompressed_size:
					print("Warning: Offset out of bounds during small offset copy.")
					break
				var value = output.decode_u8(output_pos - offset)
				output.encode_u8(output_pos, value)
				output_pos += 1

		elif (control & 0xC0) == 0xC0:
			# Offset with addition
			if idx + 2 >= input.size():
				break  # Prevent out-of-bounds
			var offset = ((control & 0x0F) << 8) | input[idx]
			idx += 1
			var add_value = input[idx]
			idx += 1
			var length = input[idx]
			idx += 1
			for a in range(length):
				if output_pos - offset < 0 or output_pos >= decompressed_size:
					print("Warning: Offset out of bounds during offset with addition.")
					break
				var value = (output.decode_u8(output_pos - offset) + add_value) & 0xFF
				output.encode_u8(output_pos, value)
				output_pos += 1

		else:
			# Unknown control byte
			print("Warning: Unknown control byte encountered.")
			break

	return output


func decompress_rle2(input: PackedByteArray, decompressed_size: int) -> PackedByteArray:
	var output = PackedByteArray()
	output.resize(decompressed_size)  # Preallocate the output buffer
	var idx = 0  # Input pointer
	var output_pos = 0  # Current position in the output buffer

	while idx < input.size():
		var control = input[idx]  # Read the control byte
		idx += 1

		if (control & 0xC0) == 0x00:
			# Literal copy
			if output_pos < decompressed_size:
				output.encode_u8(output_pos, control)
				output_pos += 1

		elif (control & 0xC0) == 0x40:
			# Offset copy
			if idx + 1 >= input.size():
				break  # Prevent out-of-bounds
			var offset = ((control & 0x0F) << 8) | input[idx]
			idx += 1
			var length = ((control & 0x30) >> 4) + 3
			for a in range(length):
				if output_pos - offset < 0 or output_pos >= decompressed_size:
					print("Warning: Offset out of bounds during offset copy.")
					break
				var value = output.decode_u8(output_pos - offset)
				output.encode_u8(output_pos, value)
				output_pos += 1

		elif (control & 0xC0) == 0x80:
			# Small offset copy
			output_pos += 1
			var offset = (control & 0x0F) + 3
			var length = ((control >> 4) & 0x03) + 3
			for a in range(length):
				if output_pos - offset < 0 or output_pos >= decompressed_size:
					print("Warning: Offset out of bounds during small offset copy.")
					break
				var value = output.decode_u8(output_pos - offset)
				output.encode_u8(output_pos, value)
				output_pos += 1

		elif (control & 0xC0) == 0xC0:
			# Offset with addition
			if idx + 2 >= input.size():
				break  # Prevent out-of-bounds
			#var offset = (control & 0x0F) + 2
			#idx += 1
			var add_value = input[idx]
			#idx += 1
			var length = (control & 0x0F) + 2
			#idx += 1
			for a in range(length):
				#if output_pos - offset < 0 or output_pos >= decompressed_size:
					#print("Warning: Offset out of bounds during offset with addition.")
					#break
				var value = input.decode_u8(idx)
				output.encode_u8(output_pos, value)
				output_pos += 1
			idx += 1
		else:
			# Unknown control byte
			print("Warning: Unknown control byte encountered.")
			break

	return output
	
	

#void FUN_0015c080(undefined4 *param_1)
#
#{
  #byte bVar1;
  #undefined4 uVar2;
  #int iVar3;
  #byte *pbVar4;
  #int iVar5;
  #undefined4 uVar6;
  #uint uVar7;
  #undefined4 uVar8;
  #int iVar9;
  #undefined4 uVar10;
  #int iVar11;
  #byte *pbVar12;
  #byte bVar13;
  #uint uVar14;
  #undefined uVar15;
  #byte bVar16;
  #byte *pbVar17;
  #undefined uVar18;
  #uint uVar19;
  #undefined uVar20;
  #uint uVar21;
  #byte *pbVar22;
  #undefined uVar23;
  #uint uVar24;
  #char cVar25;
  #uint uVar26;
  #byte *pbVar27;
  #byte *local_d0;
  #uint local_c4;
  #uint local_b8;
  #uint local_b4;
  #int local_b0;
  #int local_ac;
  #int local_a8;
  #int local_a4;
  #int local_a0;
  #int local_9c;
  #int local_94;
  #int local_90;
  #int local_8c;
  #int local_88;
  #byte *local_70;
  #
  #if ((*(char *)((int)param_1 + 0x81) == '\0') && (param_1[0x1c] != 0)) {
	#uVar2 = *param_1;
	#iVar3 = param_1[1];
	#pbVar4 = (byte *)param_1[2];
	#local_d0 = (byte *)param_1[4];
	#pbVar17 = (byte *)param_1[3];
	#iVar5 = param_1[5];
	#local_70 = (byte *)param_1[6];
	#pbVar12 = (byte *)param_1[8];
	#uVar6 = param_1[9];
	#pbVar27 = (byte *)param_1[7];
	#local_c4 = param_1[10];
	#local_b8 = param_1[0xc];
	#pbVar22 = (byte *)param_1[0xb];
	#local_b4 = param_1[0xd];
	#local_b0 = param_1[0xe];
	#local_ac = param_1[0xf];
	#local_a8 = param_1[0x10];
	#local_a4 = param_1[0x11];
	#local_a0 = param_1[0x12];
	#local_9c = param_1[0x13];
	#uVar7 = param_1[0x14];
	#local_94 = param_1[0x15];
	#local_90 = param_1[0x16];
	#local_8c = param_1[0x17];
	#local_88 = param_1[0x18];
	#bVar13 = *(byte *)((int)param_1 + 0x67);
	#cVar25 = *(char *)(param_1 + 0x19);
	#uVar26 = (uint)*(byte *)((int)param_1 + 0x65);
	#uVar24 = (uint)*(byte *)((int)param_1 + 0x66);
	#uVar15 = *(undefined *)((int)param_1 + 0x6a);
	#uVar21 = (uint)*(byte *)(param_1 + 0x1a);
	#uVar19 = (uint)*(byte *)((int)param_1 + 0x69);
	#uVar8 = param_1[0x1b];
	#iVar9 = param_1[0x1f];
	#uVar10 = param_1[0x1e];
	#FUN_0014fc50();
	#do {
	  #uVar18 = (undefined)uVar19;
	  #uVar20 = (undefined)uVar21;
	  #uVar23 = (undefined)uVar24;
	  #if (pbVar4 <= pbVar17) {
		#*(undefined *)((int)param_1 + 0x81) = 1;
		#break;
	  #}
	  #if (cVar25 == '\0') {
		#if (uVar7 <= (uint)((int)local_d0 - iVar5)) break;
		#cVar25 = '\b';
		#uVar26 = (uint)*local_d0;
		#local_d0 = local_d0 + 1;
	  #}
	  #if ((uVar26 & 1) == 0) {
		#bVar16 = *pbVar27;
		#local_ac = local_ac + 1;
		#local_9c = local_9c + 1;
		#pbVar27 = pbVar27 + 1;
		#*pbVar17 = bVar16;
		#pbVar17 = pbVar17 + 1;
		#goto LAB_0015c3a8;
	  #}
	  #bVar16 = *pbVar12;
	  #uVar24 = (uint)bVar16;
	  #uVar14 = uVar24 & 0xc0;
	  #if (uVar14 == 0x40) {
		#local_c4 = (uint)pbVar12[1] | (uVar24 & 0xf) << 8;
		#pbVar22 = pbVar17 + -local_c4;
		#uVar21 = ((uVar24 & 0x30) >> 4) + 3;
		#uVar19 = 0;
		#if (uVar21 != 0) {
		  #do {
			#uVar19 = uVar19 + 1 & 0xff;
			#*pbVar17 = *pbVar22;
			#pbVar22 = pbVar22 + 1;
			#pbVar17 = pbVar17 + 1;
		  #} while (uVar19 < uVar21);
		#}
		#pbVar12 = pbVar12 + 2;
		#local_a4 = local_a4 + 1;
#LAB_0015c454:
		#local_b0 = local_b0 + uVar21;
		#local_a8 = local_a8 + 1;
	  #}
	  #else if (uVar14 < 0x41) {
		#if ((bVar16 & 0xc0) == 0) {
		  #if ((bVar16 & 0x20) == 0) {
			#if ((bVar16 & 0x10) != 0) {
			  #pbVar12 = pbVar12 + 1;
			  #uVar21 = (uVar24 & 0xf) << 2;
			  #uVar19 = 0;
			  #if ((bVar16 & 0xf) != 0) {
				#do {
				  #uVar19 = uVar19 + 1 & 0xff;
				  #*pbVar17 = *pbVar27;
				  #pbVar27 = pbVar27 + 1;
				  #pbVar17 = pbVar17 + 1;
				#} while (uVar19 < uVar21);
			  #}
			  #goto LAB_0015c3a8;
			#}
			#local_c4 = (uint)pbVar12[1] | (uVar24 & 0xf) << 8;
			#if (bVar13 == 0) {
			  #uVar21 = *local_70 & 0xf;
			#}
			#else {
			  #bVar16 = *local_70;
			  #local_70 = local_70 + 1;
			  #uVar21 = (uint)(bVar16 >> 4);
			#}
			#uVar21 = uVar21 + 7;
			#bVar13 = bVar13 ^ 1;
		  #}
		  #else {
			#local_c4 = (uint)pbVar12[1];
			#uVar21 = (uVar24 & 0x1f) + 3;
		  #}
		  #pbVar22 = pbVar17 + -local_c4;
		  #uVar19 = 0;
		  #if (uVar21 != 0) {
			#do {
			  #uVar19 = uVar19 + 1 & 0xff;
			  #*pbVar17 = *pbVar22;
			  #pbVar22 = pbVar22 + 1;
			  #pbVar17 = pbVar17 + 1;
			#} while (uVar19 < uVar21);
		  #}
		  #pbVar12 = pbVar12 + 2;
		  #goto LAB_0015c43c;
		#}
	  #}
	  #else {
		#if (uVar14 == 0x80) {
		  #local_c4 = (uVar24 & 0xf) + 3;
		  #uVar21 = (bVar16 >> 4 & 3) + 3;
		  #pbVar22 = pbVar17 + -local_c4;
		  #uVar19 = 0;
		  #if (uVar21 != 0) {
			#do {
			  #uVar19 = uVar19 + 1 & 0xff;
			  #*pbVar17 = *pbVar22;
			  #pbVar22 = pbVar22 + 1;
			  #pbVar17 = pbVar17 + 1;
			#} while (uVar19 < uVar21);
		  #}
		  #pbVar12 = pbVar12 + 1;
#LAB_0015c43c:
		  #local_a0 = local_a0 + 1;
		  #goto LAB_0015c454;
		#}
		#if (uVar14 == 0xc0) {
		  #uVar14 = uVar24 & 0x30;
		  #if (uVar14 == 0x10) {
			#uVar21 = uVar24 & 0xf;
			#bVar16 = pbVar12[2];
			#uVar24 = (uint)bVar16;
			#local_c4 = (uint)pbVar12[1] | uVar21 << 8;
			#if (bVar13 == 0) {
			  #uVar21 = *local_70 & 0xf;
			#}
			#else {
			  #bVar1 = *local_70;
			  #local_70 = local_70 + 1;
			  #uVar21 = (uint)(bVar1 >> 4);
			#}
			#uVar21 = uVar21 + 6;
			#pbVar12 = pbVar12 + 3;
			#bVar13 = bVar13 ^ 1;
			#uVar19 = 0;
			#pbVar22 = pbVar17 + -local_c4;
			#if (uVar21 != 0) {
			  #do {
				#bVar1 = *pbVar22;
				#uVar19 = uVar19 + 1 & 0xff;
				#pbVar22 = pbVar22 + 1;
				#*pbVar17 = bVar16 + bVar1;
				#pbVar17 = pbVar17 + 1;
			  #} while (uVar19 < uVar21);
			#}
			#local_94 = local_94 + 1;
			#local_90 = local_90 + uVar21;
		  #}
		  #else if (uVar14 < 0x11) {
			#if ((bVar16 & 0x30) == 0) {
			  #uVar21 = uVar24 & 0xf;
			  #if ((bVar16 & 0xf) == 0) {
				#local_b4 = 0;
				#local_b8 = pbVar12[2] + 2;
				#bVar16 = pbVar12[1];
				#uVar24 = uVar21;
				#while (uVar24 < local_b8) {
				  #*pbVar17 = bVar16;
				  #pbVar17 = pbVar17 + 1;
				  #local_b4 = local_b4 + 1;
				  #uVar24 = local_b4;
				#}
				#pbVar12 = pbVar12 + 3;
				#uVar24 = local_b8;
			  #}
			  #else {
				#bVar16 = pbVar12[1];
				#uVar21 = uVar21 + 2;
				#uVar19 = 0;
				#if (uVar21 != 0) {
				  #do {
					#*pbVar17 = bVar16;
					#uVar19 = uVar19 + 1 & 0xff;
					#pbVar17 = pbVar17 + 1;
				  #} while (uVar19 < uVar21);
				#}
				#pbVar12 = pbVar12 + 2;
				#uVar24 = uVar21;
			  #}
			  #local_88 = local_88 + uVar24;
			  #uVar24 = (uint)bVar16;
			  #local_8c = local_8c + 1;
			#}
		  #}
		  #else if (uVar14 == 0x20) {
			#uVar19 = 0;
			#bVar16 = pbVar12[1];
			#uVar21 = (uVar24 & 0xf) + 3;
			#*pbVar17 = bVar16;
			#pbVar12 = pbVar12 + 2;
			#pbVar17 = pbVar17 + 1;
			#uVar24 = bVar16 & 0xf0;
			#if (uVar21 != 0) {
			  #do {
				#bVar16 = *local_70;
				#if (bVar13 == 0) {
				  #bVar16 = bVar16 & 0xf;
				#}
				#else {
				  #local_70 = local_70 + 1;
				  #bVar16 = bVar16 >> 4;
				#}
				#*pbVar17 = (byte)uVar24 | bVar16;
				#uVar19 = uVar19 + 1 & 0xff;
				#bVar13 = bVar13 ^ 1;
				#pbVar17 = pbVar17 + 1;
			  #} while (uVar19 < uVar21);
			#}
		  #}
		#}
	  #}
#LAB_0015c3a8:
	  #cVar25 = cVar25 + -1;
	  #uVar18 = (undefined)uVar19;
	  #uVar20 = (undefined)uVar21;
	  #uVar23 = (undefined)uVar24;
	  #uVar26 = uVar26 >> 1;
	#} while (((cVar25 != '\0') || (param_1[0x21] == 0)) ||
			#(iVar11 = FUN_0014fc50(), iVar11 <= (int)param_1[0x21]));
	#FUN_0014fc50();
	#*param_1 = uVar2;
	#param_1[2] = pbVar4;
	#param_1[4] = local_d0;
	#param_1[5] = iVar5;
	#param_1[9] = uVar6;
	#param_1[10] = local_c4;
	#param_1[0xc] = local_b8;
	#param_1[0xd] = local_b4;
	#param_1[0xe] = local_b0;
	#param_1[0xf] = local_ac;
	#param_1[0x10] = local_a8;
	#param_1[0x11] = local_a4;
	#param_1[0x12] = local_a0;
	#param_1[6] = local_70;
	#param_1[7] = pbVar27;
	#param_1[8] = pbVar12;
	#param_1[0xb] = pbVar22;
	#param_1[0x13] = local_9c;
	#param_1[0x14] = uVar7;
	#param_1[0x15] = local_94;
	#param_1[0x16] = local_90;
	#param_1[0x17] = local_8c;
	#param_1[0x18] = local_88;
	#*(byte *)((int)param_1 + 0x67) = bVar13;
	#*(undefined *)((int)param_1 + 0x6a) = uVar15;
	#param_1[0x1b] = uVar8;
	#param_1[1] = iVar3;
	#param_1[0x1f] = iVar9;
	#*(char *)(param_1 + 0x19) = cVar25;
	#*(char *)((int)param_1 + 0x65) = (char)uVar26;
	#*(undefined *)((int)param_1 + 0x66) = uVar23;
	#*(undefined *)(param_1 + 0x1a) = uVar20;
	#*(undefined *)((int)param_1 + 0x69) = uVar18;
	#param_1[3] = pbVar17;
	#param_1[0x1e] = uVar10;
	#param_1[0x22] = param_1[0x22] + 1;
	#if (*(char *)((int)param_1 + 0x81) != '\0') {
	  #uVar15 = 1;
	  #if ((int)pbVar17 - iVar9 != iVar3) {
		#uVar15 = 0xff;
	  #}
	  #*(undefined *)(param_1 + 0x20) = uVar15;
	#}
  #}
  #return;
#}


func _on_load_dat_pressed() -> void:
	file_load_dat.visible = true


func _on_file_load_dat_files_selected(paths: PackedStringArray) -> void:
	file_load_dat.visible = false
	file_load_folder.visible = true
	chose_files = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
