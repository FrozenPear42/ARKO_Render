###########################################
# Push stack operation                    #
###########################################
# %reg - register to bbe pushed           #
###########################################
.macro	push (%reg)
	sw	%reg, ($sp)
	subiu	$sp, $sp, 4
.end_macro
###########################################
# Pop stack operation                     #
###########################################
# %reg - register to be popped to         #
########################################### 
.macro	pop (%reg)
	addiu	$sp, $sp, 4
	lw	%reg, ($sp)
.end_macro
###########################################
# Jump back to adreeess from stack        #
###########################################
# Used registers                          #
# $t9 - temp                              #
########################################### 
.macro	ret
	pop	($t9)
	jr	$t9	
.end_macro
###########################################
# Calculate %source ** %n                 #
###########################################
# Used registers                          #
# $t8 - temp                              #
# $t9 - temp                              #
########################################### 
.macro	pow (%target, %source, %n)
	mov.d	%target, %source
	li	$t9, %n
	subiu	$t9, $t9, 1
pow_step:
	mul.d	%target, %target, %source
	subiu	$t9, $t9, 1
	bgtz	$t9, pow_step	
.end_macro
###########################################
# Calculate %n!                           #
###########################################
# Used registers                          #
# $t8 - temp                              #
# $t9 - temp                              #
########################################### 
.macro	factorial (%dest, %n)
	li	$t9, %n
	li	$t8, %n
	subiu	$t9, $t9, 1
factorial_step:
	mul	$t8, $t8, $t9  
	subiu	$t9, $t9, 1
	bgtz	$t9, factorial_step	
	mtc1.d	$t8, %dest
	cvt.d.w	%dest, %dest
.end_macro
###########################################
#  Swap two registers                     #
###########################################
# Used registers                          #
# $t9 - temp                              #
########################################### 
.macro	swap (%a, %b)
	move	$t9, %a
	move 	%a, %b
	move	%b, $t9
.end_macro
###########################################
#  calulate address of given matrix cell  #
###########################################
# Used registers                          #
# $t9 - temp                              #
########################################### 
.macro	mat_off	(%dest, %base, %row, %col)
	sll	%dest, %row, 5
	sll	$t9, %col, 3
	addu	%dest, %dest, $t9
	addu	%dest, %dest, %base
.end_macro
###########################################
# Print matrix                            #
###########################################
# Used registers                          #
# $a0 - for address                       #
# $v0 - syscall number                    #
# $t5 - tmp for matrix cell address       #
# $t6 - tmp for matrix cell address       #
# $t8 - row iterator                      #
# $t9 - column iterator                   #
# $f12 - arg for print double             #
########################################### 
.macro print_matrix	(%v)
	li	$t8, -1
print_matrix_rows:
	addiu	$t8, $t8, 1
	beq	$t8, 4, print_matrix_end	
	la 	$a0, new_ln
	li	$v0, 4
	syscall
	li	$t9, 0
print_matrix_cols:
	beq	$t9, 4, print_matrix_rows
	sll	$t6, $t8, 5
	sll	$t5, $t9, 3
	addu	$t6, $t6, $t5
	l.d	$f12, %v($t6)
	li	$v0, 3
	syscall
	la 	$a0, space
	li	$v0, 4
	syscall
	addiu	$t9, $t9, 1
	b	print_matrix_cols
print_matrix_end:
	la 	$a0, new_ln
	li	$v0, 4
	syscall
.end_macro
###########################################
# Print matrix                            #
###########################################
# Used registers                          #
# $a0 - for address                       #
# $v0 - syscall number                    #
# $t6 - tmp for vector cell address       #
# $t9 - column iterator                   #
# $f12 - arg for print double             #
########################################### 
.macro print_vec	(%v)
	li	$t9, 0
print_vec_cols:
	beq	$t9, 4, print_vec_end
	sll	$t6, $t9, 3
	l.d	$f12, %v($t6)
	li	$v0, 3
	syscall
	la 	$a0, space
	li	$v0, 4
	syscall
	addiu	$t9, $t9, 1
	b	print_vec_cols
print_vec_end:
	la 	$a0, new_ln
	li	$v0, 4
	syscall
.end_macro
###########################################
# Print string                            #
###########################################
# Used registers                          #
# $a0 - for address                       #
# $v0 - syscall number                    #
########################################### 
.macro	print_str(%str)
	li	$v0, 4
	la	$a0, %str
	syscall
.end_macro
###########################################
# Signal exit                             #
########################################### 
.macro	exit
	li	$v0, 10
	syscall
.end_macro
###########################################
# DEFINES                                 #
###########################################
.eqv	BUFF_SIZE	100
.eqv	BG_COLOR	0xFF112244
.eqv	BACK_COLOR	0xFFFF55CC
.eqv	FRONT_COLOR	0xFF5555CC
.eqv	SIDE_COLOR	0xFFFFCC00
.eqv	WIDTH		512
.eqv	HEIGHT		512
###########################################
# DATA                                    #
###########################################
	.data
###########################################
# Bitmap data - 0x40000 = 512*512         #
###########################################	
bitmap:	.space	0x100000
###########################################
# BMP Header                              #
###########################################
#	        B     M     size                    RSV   RSV   RSV   RSV   off    
head:   .byte	0x42, 0x4D, 0x7A, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7A, 0x00, 0x00, 0x00
#	        Header size             Width                   Height
	.byte	0x6C, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00
#	        plane       bpp         compression             size
	.byte	0x01, 0x00, 0x20, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00
#	        h_dpm                   v_dpm                   colors_palette
	.byte	0x13, 0x0B, 0x00, 0x00, 0x13, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#	        important colors        red_mask                green_mask
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00
#	        blue_mask               alpha_mask		windows_space
	.byte	0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x20, 0x6E, 0x69, 0x57
#	        unused
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#	        unused
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#	        red_gamma               green_gamma             blue_gamma
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
###########################################
# Constants                               #
###########################################		
pi_x_2: 	.double 6.28318530718
pi_2:		.double 1.57079632679
pi_4:		.double 0.78539816321
pi_6:		.double 0.52359877559
pi_8:		.double 0.39269908169
pi_180:		.double	0.01745329251
one:		.double	1.00000000000
zero:		.double	0.00000000000
five:		.double	5.00000000000
dim:		.double 512.000000000
###########################################
# Vertices table                          #
###########################################		
vert:
v0:	.double -1.0 , -1.0, -1.0,  1.0
v1:	.double  1.0 , -1.0, -1.0,  1.0
v2:	.double  1.0 ,  1.0, -1.0,  1.0
v3:	.double -1.0 ,  1.0, -1.0,  1.0
v4:	.double -1.0 , -1.0,  1.0,  1.0
v5:	.double  1.0 , -1.0,  1.0,  1.0
v6:	.double  1.0 ,  1.0,  1.0,  1.0
v7:	.double -1.0 ,  1.0,  1.0,  1.0
###########################################
# Result vertices table                   #
###########################################		
vert_res:
rv0:	.double  0.0 : 4
rv1:	.double  0.0 : 4
rv2:	.double  0.0 : 4
rv3:	.double  0.0 : 4
rv4:	.double  0.0 : 4
rv5:	.double  0.0 : 4
rv6:	.double  0.0 : 4
rv7:	.double  0.0 : 4
###########################################
# Init model(rotation) matrix             #
###########################################		
m_mod:	.double  1.0,  0.0,  0.0,  0.0
	.double  0.0,  1.0,  0.0,  0.0
	.double  0.0,  0.0,  1.0,  0.0
	.double  0.0,  0.0,  0.0,  1.0
###########################################
# Init translation matrix                 #
###########################################		
m_trans:	.double  1.0,  0.0,  0.0,  0.0
		.double  0.0,  1.0,  0.0,  0.0
		.double  0.0,  0.0,  1.0,  5.0
		.double  0.0,  0.0,  0.0,  1.0
###########################################
# Camera matrix                           #
###########################################
m_view:	.double  1.0   0.0,  0.0,   0.0
	.double  0.0,  1.0,  0.0,   0.0
	.double  0.0,  0.0,  1.0,   0.0
	.double  0.0,  0.0,  0.0,   1.0
###########################################
# Projection matrix                       #
#####################################################
# cot(fov/2)     0             0            0       #
#     0      cot(fov/2)        0            0       #
#     0          0       (f+n/)(f-n)   -2*f*n/(f-n) #
#     0          0            1             0       #
#####################################################
# a = 1:1                                 #
# fov = 90deg                             #
# f - far = 500                           #
# n - near =  0.1                         #
###########################################
m_proj: .double  1.00000000,  0.00000000,  0.00000000, 	0.000000000
	.double  0.00000000,  1.00000000,  0.00000000, 	0.000000000
	.double  0.00000000,  0.00000000,  1.00040008, -0.200040008
	.double  0.00000000,  0.00000000,  1.00000000,	0.000000000
###########################################
# Result matrix                           #
###########################################
m_res:  .double  0.0 : 16
###########################################
# Temp matrix                             #
###########################################
m_tmp:  .double  0.0 : 16
###########################################
# Strings                                 #
###########################################	
filename:	.space	BUFF_SIZE
space:		.asciiz	"\t\t"
new_ln:		.asciiz "\n"
msg_error:	.asciiz	"Error creating file"
msg_success:	.asciiz	"Yay!"
msg_filename:	.asciiz	"Enter filename: "
msg_rotation:	.asciiz "Enter rotation "
msg_position:	.asciiz	"Enter observer position "
msg_x:	        .asciiz "x: "
msg_y:	        .asciiz "y: "
msg_z:		.asciiz "z: "
test_file:	.asciiz	"xxx.bmp"
###########################################
# CODE                                    #
###########################################	
	.text
	.globl main
###########################################
# Main function, entry point              #
###########################################
# Args                                    #
###########################################
# None                                    #
###########################################
# Result                                  #
###########################################
# --------------------------------------- #
###########################################
# Used registers                          #
###########################################
#                                         #
###########################################  	
main:
#	jal	test_rotation
#	exit
	
	print_str(msg_filename)
	li	$v0, 8
	la	$a0, filename
	li	$a1, BUFF_SIZE
	syscall
	
	xor	$t0, $t0, $t0
rm_nl_loop:
	lb	$t1, filename($t0)
	addiu	$t0, $t0, 1
	bnez	$t1, rm_nl_loop
	beq	$t1, BUFF_SIZE, rm_nl_end
	subiu	$t0, $t0, 2
	sb	$zero, filename($t0)
rm_nl_end:	
		
	l.d	$f2, pi_180
 	print_str(msg_rotation)		
	print_str(msg_x)	
	li	$v0, 7
	syscall
	mul.d	$f12, $f0, $f2
	
	print_str(msg_rotation)		
	print_str(msg_y)	
	li	$v0, 7
	syscall
	mul.d	$f14, $f0, $f2
	
	print_str(msg_rotation)		
	print_str(msg_z)	
	li	$v0, 7
	syscall
	mul.d	$f16, $f0, $f2
	
	jal	set_rotation
	
	print_str(msg_position)		
	print_str(msg_x)	
	li	$v0, 7
	syscall
	mov.d	$f12, $f0
	
	print_str(msg_position)		
	print_str(msg_y)	
	li	$v0, 7
	syscall
	mov.d	$f14, $f0
	
	print_str(msg_position)		
	print_str(msg_z)	
	li	$v0, 7
	syscall
	mov.d	$f16, $f0
	
	jal	set_translation
	
	jal	render	
	
	la	$a0, filename
	jal	save_to_file	
	exit
###########################################
# Render                                  #
###########################################
# Args                                    #
###########################################
# None directly                           #
# vert                                    #
# m_mod                                   #
# m_view                                  #
# m_proj                                  #
###########################################
# Result                                  #
###########################################
# Rendered bitmap                         #
###########################################
# Used registers                          #
###########################################
# $v0, $a0, $a1, $a2, $a3 - args          #
# $s0, $s1 - tmp                          #
###########################################
render:
	push	($ra)
	
	jal 	clear_screen
	
	la	$a0, m_res
	la	$a1, m_trans
	la	$a2, m_mod
	jal	mat_mul	

	la	$a0, m_tmp
	la	$a1, m_view
	la	$a2, m_res
	jal	mat_mul	

	la	$a0, m_res
	la	$a1, m_proj
	la	$a2, m_tmp
	jal	mat_mul

	print_matrix(m_res)

	li	$s0, 8
	la	$a1, m_res
render_vert_loop:
	bltz	$s0, render_vert_loop_end	# end loop
	mul	$s1, $s0, 32			# calculate offset for vertices	
	la	$a0,  rv0			# load result vertices table address to $a0
	add	$a0, $a0, $s1			# offset $a0
	la	$a2,  v0			
	add	$a2, $a2, $s1
	jal	mat_mul_vec
	la	$a0, rv0
	add	$a0, $a0, $s1			# offset $a0
	jal	vec_w_norm
	jal	vec_to_viewport
	subiu	$s0, $s0, 1
	b	render_vert_loop
render_vert_loop_end:
	print_str	(new_ln)
	print_vec	(rv0)	
	print_vec	(rv1)	
	print_vec	(rv2)	
	print_vec	(rv3)	
	print_vec	(rv4)
	print_vec	(rv5)
	print_vec	(rv6)
	print_vec	(rv7)
	
	li	$v0, BACK_COLOR	
	la	$a0, rv0
	la	$a1, rv1
	jal	draw_line_3d

	la	$a0, rv1
	la	$a1, rv2
	jal	draw_line_3d

	la	$a0, rv2
	la	$a1, rv3
	jal	draw_line_3d

	la	$a0, rv3
	la	$a1, rv0
	jal	draw_line_3d

	li	$v0, FRONT_COLOR			
	la	$a0, rv4
	la	$a1, rv5
	jal	draw_line_3d

	la	$a0, rv5
	la	$a1, rv6
	jal	draw_line_3d

	la	$a0, rv6
	la	$a1, rv7
	jal	draw_line_3d

	la	$a0, rv7
	la	$a1, rv4
	jal	draw_line_3d
	
	li	$v0, SIDE_COLOR		
	la	$a0, rv0
	la	$a1, rv4
	jal	draw_line_3d

	la	$a0, rv1
	la	$a1, rv5
	jal	draw_line_3d

	la	$a0, rv2
	la	$a1, rv6
	jal	draw_line_3d

	la	$a0, rv3
	la	$a1, rv7
	jal	draw_line_3d
	ret

###########################################
# Update m_view with camera position      #
###########################################
# Args                                    #
###########################################
# $f12 - x                                #  
# $f14 - y                                #
# $f16 - z                                #
###########################################
# Result                                  #
###########################################
# updated m_view matrix                   #
###########################################
# Used registers                          #
###########################################
#                                         #
###########################################
set_translation:
	push	($ra)
	
	l.d	$f18, zero
	l.d	$f20, one
	
# 1,1
	s.d	$f20, m_trans + 0
# 1,2
	s.d	$f18, m_trans + 8
# 1,3
	s.d	$f18, m_trans + 16
# 1,4 - x
	s.d	$f12, m_trans + 24
# 2,1
	s.d	$f18, m_trans + 32
# 2,2
	s.d	$f20, m_trans + 40
# 2,3
	s.d	$f18, m_trans + 48
# 2,4 - y
	neg.d	$f22, $f14
	s.d	$f22, m_trans + 56
# 3,1
	s.d	$f18, m_trans + 64
# 3,2
	s.d	$f18, m_trans + 72
# 3,3
	s.d	$f20, m_trans + 80
# 3,4 - z
	neg.d	$f22, $f16
	s.d	$f22, m_trans + 88		
# 4,1
	s.d	$f18, m_trans + 96				
# 4,2
	s.d	$f18, m_trans + 104				
# 4,3
	s.d	$f18, m_trans + 112				
# 4,4
	s.d	$f20, m_trans + 120
	ret

###########################################
# Update m_mod matrix with rotations      #
###########################################
# Args                                    #
###########################################
# $f12 - x                                #  
# $f14 - y                                #
# $f16 - z                                #
###########################################
# Result                                  #
###########################################
# rotation matrix in m_mod                #
###########################################
# Used registers                          #
###########################################
# $f0 - sine and cosine result            #
# $f16 - tmp                              #
# $f18 - tmp                              #
# $f20 - sin(x)                           #
# $f22 - cos(x)                           #
# $f24 - sin(y)                           #
# $f26 - cos(y)                           #
# $f28 - sin(z)                           #
# $f30 - cos(z)                           #
###########################################
set_rotation:
	push	($ra)
	mov.d	$f0, $f12
	jal	sine
	mov.d	$f20, $f2
	jal	cosine
	mov.d	$f22, $f2

	mov.d	$f0, $f14
	jal	sine
	mov.d	$f24, $f2
	jal	cosine
	mov.d	$f26, $f2
	
	mov.d	$f0, $f16
	jal	sine
	mov.d	$f28, $f2
	jal	cosine
	mov.d	$f30, $f2
	
#############################################################################################
# cos(y)cos(z)   sin(x)sin(y)cos(z) - cos(x)sin(z)   cos(x)sin(y)cos(z) + sin(x)sin(z)  0   #
# cos(y)sin(z)   sin(x)sin(y)sin(z) + cos(x)cos(z)   cos(x)sin(y)sin(z) - sin(x)cos(z)  0   #
#   -sin(y)	          sin(x)cos(y)                          cos(x)cos(y)            0   #
#      0                       0                                     0                  1   #
#############################################################################################

# 1,1
	mul.d	$f16, $f26, $f30 #cos(y)cos(z)
	s.d	$f16, m_mod + 0
# 1,2
	mul.d	$f16, $f20, $f24 #sin(x)sin(y)-
	mul.d	$f16, $f16, $f30 #sin(x)sin(y)cos(z)
	mul.d	$f18, $f22, $f28 #cos(x)sin(z)	
	sub.d	$f16, $f16, $f18 #sin(x)sin(y)cos(z) - cos(x)sin(z)
	s.d	$f16, m_mod + 8
# 1,3
	mul.d	$f16, $f22, $f24 #cos(x)sin(y)
	mul.d	$f16, $f16, $f30 #cos(x)sin(y)cos(z)
	mul.d	$f18, $f20, $f28 #sin(x)sin(z)
	add.d	$f16, $f16, $f18 #cos(x)sin(y)cos(z) + sin(x)sin(z)
	s.d	$f16, m_mod + 16
# 1,4
	l.d	$f16, zero
	s.d	$f16, m_mod + 24

# 2,1
	mul.d	$f16, $f26, $f28 #cos(y)sin(z)
	s.d	$f16, m_mod + 32
# 2,2
	mul.d	$f16, $f20, $f24 #sin(x)sin(y)
	mul.d	$f16, $f16, $f28 #sin(x)sin(y)sin(z)
	mul.d	$f18, $f22, $f30 #cos(x)cos(z)
	add.d	$f16, $f16, $f18 #cos(x)sin(y)sin(z) + cos(x)cos(z)
	s.d	$f16, m_mod + 40
# 2,3
	mul.d	$f16, $f22, $f24 #cos(x)sin(y)
	mul.d	$f16, $f16, $f28 #cos(x)sin(y)sin(z)
	mul.d	$f18, $f20, $f30 #sin(x)cos(z)
	sub.d	$f16, $f16, $f18 #cos(x)sin(y)sin(z) - sin(x)cos(z)
	s.d	$f16, m_mod + 48
# 2,4
	l.d	$f16, zero
	s.d	$f16, m_mod + 56

# 3,1
	neg.d 	$f16, $f24	 #sin(y)
	s.d	$f16, m_mod + 64
# 3,2
	mul.d	$f16, $f20, $f26 #sin(x)cos(y)
	s.d	$f16, m_mod + 72
# 3,3
	mul.d	$f16, $f22, $f26 #cos(x)cos(y)
	s.d	$f16, m_mod + 80
# 3,4
	l.d	$f16, zero
	s.d	$f16, m_mod + 88		
# 4,1
	s.d	$f16, m_mod + 96				
# 4,2
	s.d	$f16, m_mod + 104				
# 4,3
	s.d	$f16, m_mod + 112				
# 4,4
	l.d	$f16, one
	s.d	$f16, m_mod + 120				

	ret

###########################################
# set matrix to zero-matrix               #
###########################################
# Args                                    #
###########################################
# $a0 - Matrix                            #  
###########################################
# Result                                  #
###########################################
# [0] at $a0                              #
###########################################
# Used registers                          #
###########################################
# $t1 - iterator                          #
# $t2 - for adddress calculation          #
# $f0 - zero value                        #
###########################################
mat_clr:
	push	($ra)				
	li	$t1, 0
	l.d	$f0, zero
mat_clr_loop:
	sll	$t2, $t1, 3
	addu	$t2, $a0, $t2
	s.d	$f0, ($t2)
	addiu	$t1, $t1, 1
	beq	$t1, 16, mat_clr_end
	b	mat_clr_loop
mat_clr_end:
	ret
###########################################
# set matrix to zero-matrix               #
###########################################
# Args                                    #
###########################################
# $a0 - Vector                            #  
###########################################
# Result                                  #
###########################################
# [0] at $a0                              #
###########################################
# Used registers                          #
###########################################
# $t1 - iterator                          #
# $t2 - for adddress calculation          #
# $f0 - zero value                        #
###########################################	
vec_clr:
	push	($ra)				
	li	$t1, 0
	l.d	$f0, zero
vec_clr_loop:
	sll	$t2, $t1, 3
	addu	$t2, $a0, $t2
	s.d	$f0, ($t2)
	addiu	$t1, $t1, 1
	beq	$t1, 4, vec_clr_end
	b	vec_clr_loop
vec_clr_end:
	ret	
###########################################
# Multiply matrices: C = A*B              #
###########################################
# Args                                    #
###########################################
# $a1 - Matrix A                          #  
# $a2 - Matrix B                          #
###########################################
# Result                                  #
###########################################
# $a0 - result matrix C                   #
###########################################
# Used registers                          #
###########################################
# $t0 - matrix size = 4                   #
# $t1, $t2, $t3 - iterators               #
# $t4, $t5, $t6 - indexes                 #
# $f0, $f2, $f4 - matrix fields values    #
###########################################
mat_mul:
	push	($ra)
	li	$t0, 4

	jal	mat_clr

mat_mul_1:	
	li	$t1, -1
mat_mul_1_step:
	addiu	$t1, $t1, 1
	bge	$t1, $t0, mat_mul_end
mat_mul_2:
	li	$t2, -1
mat_mul_2_step:
	addiu	$t2, $t2, 1
	bge	$t2, $t0, mat_mul_1_step
mat_mul_3:
	li	$t3, -1
mat_mul_3_step:
	addiu	$t3, $t3, 1
	bge	$t3, $t0, mat_mul_2_step	
	mat_off	($t4, $a0, $t1, $t2)	#load res addr to $t4
	mat_off	($t5, $a1, $t1, $t3)	#load A addr to $t5
	mat_off	($t6, $a2, $t3, $t2)	#load B addr to $t6
	l.d	$f0, ($t4)
	l.d	$f2, ($t5)
	l.d	$f4, ($t6)
	mul.d	$f2, $f2, $f4
	add.d	$f0, $f0, $f2
	s.d	$f0, ($t4)
	b	mat_mul_3_step
mat_mul_end:
	ret
###########################################
# Multiply matrix by vector: C = A*V      #
###########################################
# Args                                    #
###########################################
# $a1 - Matrix A                          #  
# $a2 - Vector V                          #
###########################################
# Result                                  #
###########################################
# $a0 - result vector C                   #
###########################################
# Used registers                          #
###########################################
# $t0 - matrix size = 4                   #
# $t1, $t2      - iterators               #
# $t4, $t5, $t6 - indexes                 #
# $f0, $f2, $f4 - matrix fields values    #
###########################################
mat_mul_vec:
	push	($ra)
	
	jal	vec_clr
																																																			
	li	$t0, 4
mat_mul_vec_1:	
	li	$t1, -1
mat_mul_vec_1_step:
	addiu	$t1, $t1, 1
	bge	$t1, $t0, mat_mul_vec_end	
mat_mul_vec_2:
	li	$t2, -1
mat_mul_vec_2_step:
	addiu	$t2, $t2, 1
	bge	$t2, $t0, mat_mul_vec_1_step
	mat_off	($t4, $a0, $zero, $t1)	#load res addr to $t4
	mat_off	($t5, $a1, $t1, $t2)	#load A addr to $t5
	mat_off	($t6, $a2, $zero, $t2)	#load B addr to $t6
	l.d	$f0, ($t4)
	l.d	$f2, ($t5)
	l.d	$f4, ($t6)
	mul.d	$f2, $f2, $f4
	add.d	$f0, $f0, $f2
	s.d	$f0, ($t4)
	b	mat_mul_vec_2_step
mat_mul_vec_end:	
	ret																	

###########################################
# W-normalize given vector                #
###########################################
# Args                                    #
###########################################
# $a0 - Vector V address                  #
###########################################
# Result                                  #
###########################################
# w-normalized vector in  $a0             #
###########################################
# Used registers                          #
###########################################
# $f0, $f2 - temporary values             #
###########################################
vec_w_norm:
	push	($ra)
	# LOAD w to $f0
	l.d	$f0, 24($a0)
	#abs for w, dont flip
	abs.d	$f0, $f0
	
	# divide 
	l.d	$f2, ($a0)
	div.d 	$f2, $f2, $f0
	s.d	$f2, ($a0)
	
	l.d	$f2, 8($a0)
	div.d 	$f2, $f2, $f0
	s.d	$f2, 8($a0)
	
	l.d	$f2, 16($a0)
	div.d 	$f2, $f2, $f0
	s.d	$f2, 16($a0)
	
	div.d 	$f2, $f0, $f0
	s.d	$f2, 24($a0)
	
	ret
###########################################
# Convert UV to Viewport coordinates      #
###########################################
# Args                                    #
###########################################
# $a0 - Vector V address                  #
###########################################
# Result                                  #
###########################################
# vector in viewport coordinates in $a0   #
###########################################
# Used registers                          #
###########################################
# $f0, $f2, $f4 - temporary values        #
# $t0           - temporary values        #
###########################################
vec_to_viewport:
	push	($ra)
	l.d	$f0, one
	
	li	$t0, 256 #512/2
	mtc1.d	$t0, $f2
	cvt.d.w	$f2, $f2
			
	l.d	$f4, ($a0)
	add.d	$f4, $f4, $f0
	mul.d	$f4, $f4, $f2
	s.d	$f4, ($a0)
	
	l.d	$f4, 8($a0)
	add.d	$f4, $f4, $f0
	mul.d	$f4, $f4, $f2
	s.d	$f4, 8($a0)
	
	l.d	$f4, 16($a0)
	add.d	$f4, $f4, $f0
	
	add.d	$f0, $f0, $f0 # get 2 in f0
	div.d	$f4, $f4, $f0
	s.d	$f4, 16($a0)
	
	ret
###########################################
# Calculate sine of x, where x is in rad  #
###########################################
# Args                                    #
###########################################
# $f0 - x, is not changed                 #  
###########################################
# Result                                  #
###########################################
# $f2 - result                            #
###########################################
# Used registers                          #
###########################################
# $f4 - x clamped to 2pi                  #
# $f6, $f8 - temporary                    #
# $t4, $t5, $t6 - indexes                 #
# $f0, $f2, $f4 - matrix fields values    #
###########################################
sine:
	push ($ra)	
	
	l.d	$f8, pi_x_2	
	div.d	$f10, $f0, $f8	
	round.w.d $f10, $f10
	cvt.d.w	$f10, $f10
	mul.d	$f10, $f10, $f8
	sub.d	$f4, $f0, $f10

	mov.d	$f2, $f4
	
	pow	($f6, $f4, 3)
	factorial ($f8, 3)
	div.d	$f6, $f6, $f8
	sub.d	$f2, $f2, $f6

	pow	($f6, $f4, 5)		
	factorial ($f8, 5)
	div.d	$f6, $f6, $f8
	add.d	$f2, $f2, $f6

	pow	($f6, $f4, 7)	
	factorial ($f8, 7)
	div.d	$f6, $f6, $f8
	sub.d	$f2, $f2, $f6

	pow	($f6, $f4, 9)	
	factorial ($f8, 9)
	div.d	$f6, $f6, $f8
	add.d	$f2, $f2, $f6		

	pow	($f6, $f4, 11)	
	factorial ($f8, 11)
	div.d	$f6, $f6, $f8
	sub.d	$f2, $f2, $f6		
	
	pow	($f6, $f4, 13)	
	factorial ($f8, 13)
	div.d	$f6, $f6, $f8
	add.d	$f2, $f2, $f6		
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																											
	ret
###########################################
# Calculate cos(x), where x is in rad     #  
###########################################
# Args                                    #
###########################################
# $f0 - x, is not changed                 #  
###########################################
# Result                                  #
###########################################
# $f2 - result                            #
###########################################
# Used registers                          #
###########################################
# $f10 - temporary                        #
# registers used by sine                  #
###########################################
cosine:
	push	($ra)
	l.d	$f10, pi_2
	sub.d	$f0, $f0, $f10
	jal	sine
	l.d	$f10, pi_2
	add.d	$f0, $f0, $f10
	ret
###########################################
# Put pixel on bitmap                     #  
###########################################
# Args                                    #
###########################################
# $a0 - x1                                #
# $a1 - y1                                #
# $v0 - color (0xAARRGGBB)                #
###########################################
# Result                                  #
###########################################
# Pixel on bitmap                         #
###########################################
# Used registers                          #
###########################################
# $t9 - y-offset                          #
# $t8 - x-offset                          #
###########################################
draw_pixel:
	push	($ra)
	blt	$a0, 0, out_pixel
	blt	$a1, 0, out_pixel
	bge	$a0, 512, out_pixel
	bge	$a1, 512, out_pixel
	
	li	$t9, 511
	subu	$t9, $t9, $a1
	
	mulu	$t9, $t9, 512	# $t9 - y offset
	sll	$t9, $t9, 2
	sll	$t8, $a0, 2
	addu	$t9, $t9, $t8  	# +x 
	sw	$v0, bitmap($t9)	# set color
out_pixel:
	ret

###########################################
# Draw line from A to B where A, B are    #
# Vectors at $a0, and $a1 adressess       #  
# Liang–Barsky                            #
###########################################
# Args                                    #
###########################################
# $a0 - A                                 #
# $a1 - B                                 #
# $v0 - color (0xAARRGGBB)                #
###########################################
# Result                                  #
###########################################
# Line from A to B                        #
###########################################
# Used registers                          #
###########################################
# $f0 -  x0                               #
# $f2 -  y0                               #
# $f4 -  z0                               #
# $f6 -  x1                               #
# $f8 -  y1                               #
# $f10 - z1                               #
# $f16 - t_MIN                            #
# $f18 - t_MAX                            #
# $f20 - dx                               #
# $f22 - dy                               #
# $f24 - p                                #
# $f26 - q                                #
# $f28 - r                                #
# $f30 - tmp                              #
###########################################
.eqv	d3d_x0 $f0
.eqv	d3d_y0 $f2
.eqv	d3d_z0 $f4
.eqv	d3d_x1 $f6
.eqv	d3d_y1 $f8
.eqv	d3d_z1 $f10
.eqv	d3d_zero $f12
.eqv	d3d_dim  $f14
.eqv	d3d_t_min $f16
.eqv	d3d_t_max $f18
.eqv	d3d_t_max $f18
.eqv	d3d_dx $f20
.eqv	d3d_dy $f22
.eqv	d3d_p $f24
.eqv	d3d_q $f26
.eqv	d3d_r $f28
draw_line_3d:
	push	($ra)
	
	#load A
	l.d	d3d_x0, 0($a0)
	l.d	d3d_y0, 8($a0)
	l.d	d3d_z0, 16($a0)
	#load B
	l.d	d3d_x1, 0($a1)
	l.d	d3d_y1, 8($a1)
	l.d	d3d_z1, 16($a1)
	
	l.d	d3d_zero, zero
	l.d	d3d_dim,  dim
		
	l.d	d3d_t_min, zero
	l.d	d3d_t_max, one
	
	
	c.lt.d	0, d3d_z0, d3d_zero	# z0 < 0
	c.lt.d	1, d3d_z1, d3d_zero	# z1 < 0
	
	bc1f	0, d3d_draw
	bc1f	1, d3d_draw
	b	d3d_no_draw
	
d3d_draw:	
	sub.d	d3d_dx, d3d_x1, d3d_x0		# dx
	sub.d	d3d_dy, d3d_y1, d3d_y0		# dy

.macro	d3d_step()
	abs.d	$f30, d3d_p
	c.eq.d	0, $f30, d3d_zero		# p == 0
	c.lt.d	1, d3d_p, d3d_zero		# p < 0
	c.lt.d	2, d3d_q, d3d_zero		# q < 0

	bc1f	0, d3d_step_pne0		# p != 0
	bc1t	2, d3d_no_draw			# q < 0
	b	d3d_load_val 			# q >= 0 - line inside
d3d_step_pne0:	
	div.d	d3d_r, d3d_q, d3d_p		# r = q/p
	c.lt.d	3, d3d_r, d3d_t_min		# r < t_min
	c.lt.d	4, d3d_r, d3d_t_max		# r < t_max
	bc1f	1, d3d_step_pgt0		# p >= 0	
d3d_step_plt0:
	bc1f	4, d3d_no_draw			# p < 0 && r < t_max
	movf.d	d3d_t_min, d3d_r, 3		# r >= t_min -> t_min = r
	b	d3d_step_end 
d3d_step_pgt0:
	bc1t	3, d3d_no_draw			# p >= 0 && r < t_min
	movt.d	d3d_t_max, d3d_r, 4		# r < t_max - > t_max = r
d3d_step_end:
.end_macro	

						
d3d_left_edge:
	neg.d	d3d_p, d3d_dx		# -dx
	sub.d	d3d_q, d3d_x0, d3d_zero	# x - left
	d3d_step()	
d3d_right_edge:
	mov.d	d3d_p, d3d_dx		# dx
	sub.d	d3d_q, d3d_dim, d3d_x0	# right - x
	d3d_step()
d3d_down_edge:
	neg.d	d3d_p, d3d_dy		# -dy
	sub.d	d3d_q, d3d_y0, d3d_zero	# y - down
	d3d_step()
d3d_up_edge:
	mov.d	d3d_p, d3d_dy		# dy
	sub.d	d3d_q, d3d_dim, d3d_y0	# up - y
	d3d_step()
	
d3d_correct:
	mov.d	$f12, d3d_x0
	mov.d	$f14, d3d_y0
	
	mul.d	$f30, d3d_t_min, d3d_dx		# t_MIN * dx
	add.d	d3d_x0, $f12, $f30		# x = x + t_min * dx
	
	mul.d	$f30, d3d_t_min, d3d_dy		# t_MIN * dy
	add.d	d3d_y0, $f14, $f30		# y= y + t_min * dy
	
	mul.d	$f30, d3d_t_max, d3d_dx		# t_MAX * dx
	add.d	d3d_x1, $f12, $f30		# x = x + t_max * dx
	
	mul.d	$f30, d3d_t_max, d3d_dy		# t_MAX * dy
	add.d	d3d_y1, $f14, $f30		# y = y + t_max * dy
				
							
d3d_load_val:	
	round.w.d	$f0, $f0
	mfc1		$a0, $f0
	round.w.d	$f2, $f2
	mfc1		$a1, $f2	

	round.w.d	$f6, $f6
	mfc1		$a2, $f6
	round.w.d	$f8, $f8
	mfc1		$a3, $f8	
	jal	draw_line
d3d_no_draw:
	ret
	
###########################################
# Draw line from (x1,y1) to (x2,y2)       #  
# Bernsenham algorithm                    #  
###########################################
# Args                                    #
###########################################
# $a0 - x1                                #
# $a1 - y1                                #
# $a2 - x2                                #
# $a3 - y2                                #
# $v0 - color (0xAARRGGBB)                #
###########################################
# Result                                  #
###########################################
# Line from (x1,y1) to (x2,y2)            #
###########################################
# Used registers                          #
###########################################
# $t0 - x_dir                             #
# $t1 - y_dir                             #
# $t2 - dx                                #
# $t3 - dy                                #
# $t4 - a                                 #
# $t5 - b                                 #
# $t6 - d - error                         #
###########################################
draw_line:
	push	($ra)
x_direction:
	bgt	$a0, $a2, x_neg		# x1 <= x2
	li	$t0, 1			# we go up on x
	subu	$t2, $a2, $a0		# we have to go by x2-x1
	b	y_direction
x_neg:					# x1 > x2
	li	$t0, -1			# we go down on x
	subu	$t2, $a0, $a2		# we have to go by x1-x2
y_direction:	
	bgt	$a1, $a3, y_neg
	li	$t1, 1
	subu	$t3, $a3, $a1
	b	line_begin
y_neg:	
	li	$t1, -1
	subu	$t3, $a1, $a3		
line_begin:	
	jal	draw_pixel
	blt	$t2, $t3, draw_oy	# dx >= dy -> OX is longer
draw_ox:	
	subu	$t4, $t3, $t2		# a = dy - dx < 0
	sll	$t4, $t4, 1		# a = a * 2
	sll	$t5, $t3, 1		# b = dy * 2
	subu	$t6, $t5, $t2		# d = b - dx
draw_ox_step:
	beq	$a0, $a2, line_end	# x1 == x2 -> end
	bgez	$t6, draw_ox_move	# delta >= 0 -> move in y
draw_ox_stay:
	addu	$t6, $t6, $t5		# delta + b
	addu	$a0, $a0, $t0		# x step
	b	draw_ox_endstep
draw_ox_move:	
	addu	$a0, $a0, $t0 		# x step 
	addu	$a1, $a1, $t1		# y step
	addu	$t6, $t6, $t4 		# delta + a
draw_ox_endstep:
	jal	draw_pixel
	b	draw_ox_step	
			
draw_oy:
	subu	$t4, $t2, $t3		# a = dx - dy < 0
	sll	$t4, $t4, 1		# a = a * 2
	sll	$t5, $t2, 1		# b = dx *2
	subu	$t6, $t5, $t3		# d = b - dy
draw_oy_step:
	beq	$a1, $a3, line_end
	bgez	$t6, draw_oy_move
draw_oy_stay:
	addu	$t6, $t6, $t5
	addu	$a1, $a1, $t1
	b	draw_oy_endstep
draw_oy_move:	
	addu	$a0, $a0, $t0
	addu	$a1, $a1, $t1
	addu	$t6, $t6, $t4
draw_oy_endstep:
	jal	draw_pixel
	b	draw_oy_step	
line_end:	
	ret
	
###########################################
# clear screen                            #  
###########################################
# Args                                    #
###########################################
# None                                    #
###########################################
# Result                                  #
###########################################
# Cleared bitmap                          #
###########################################
# Used registers                          #
###########################################
# $a1 - write mode                        #
# $a2 - no flags                          #
# $t9 - file descriptor                   #
###########################################    
clear_screen:
	push	($ra)
	li	$t0, 0
	li	$t1, BG_COLOR
clear_screen_loop:
	beq	$t0, 0x100000, clear_screen_end
	sw	$t1, bitmap($t0)
	addiu	$t0, $t0, 4
	b	clear_screen_loop
clear_screen_end:	
	ret	
	
###########################################
# Save bitmap to file                     #  
###########################################
# Args                                    #
###########################################
# $a0 - filename                          #
###########################################
# Result                                  #
###########################################
# BMP File 'filename'                     #
###########################################
# Used registers                          #
###########################################
# $a1 - write mode                        #
# $a2 - no flags                          #
# $t9 - file descriptor                   #
###########################################    
save_to_file:
	push	($ra)
	# open file
	li	$a1, 1	
	li 	$a2, 0	
	li	$v0, 13
	syscall
	# success opening?    
	blez	$v0, error
	# save file descriptor
	move 	$t9, $v0
	# write BMP head
	li  	$v0, 15
	move	$a0, $t9
	la	$a1, head
	li	$a2, 122
	syscall
	# write bitmap data
	li  	$v0, 15
	move	$a0, $t9
	la	$a1, bitmap
	li	$a2, 0x100000
	syscall
	# close file
	li	$v0, 16
	move 	$a0, $t9
	syscall
	# Yay
	la	$a0, msg_success
	li	$v0, 4
	syscall
	# return
	ret	
error:
	# Ehh...
	la 	$a0, msg_error
	li	$v0, 4
	syscall
	#return
	ret
###########################################
# Test rotations                          #  
###########################################
# Args                                    #
###########################################
# None                                    #
###########################################
# Result                                  #
###########################################
# BMP Files xxx.bmp                       #
###########################################
# Used registers                          #
###########################################
#                                         #
########################################### 
test_rotation:
	push	($ra)
		
	li	$s2, 0
	li	$t1, 'X'
	sb	$t1, test_file
	
	l.d	$f12, zero
	l.d	$f14, zero
	l.d	$f16, five
	neg.d	$f16, $f16
	jal	set_translation
	print_matrix(m_trans)
	
test_rot_loop_x:
	beq	$s2, 12, test_rot_loop_x_end
	addiu	$t1, $s2, 'A'
	sb	$t1, test_file + 1
	
	mtc1.d	$s2, $f0
	cvt.d.w	$f0, $f0		
	
	l.d	$f12, pi_6
	mul.d	$f12, $f12, $f0
	l.d	$f14, zero
	l.d	$f16, zero
	jal	set_rotation
	jal	clear_screen
	jal	render
	la	$a0, test_file
	jal 	save_to_file
	addiu	$s2, $s2, 1
	b	test_rot_loop_x
test_rot_loop_x_end:
	
	li	$s2, 0
	li	$t1, 'Y'
	sb	$t1, test_file
test_rot_loop_y:
	beq	$s2, 12, test_rot_loop_y_end
	addiu	$t1, $s2, 'A'
	sb	$t1, test_file + 1
	
	mtc1.d	$s2, $f0
	cvt.d.w	$f0, $f0		
	
	l.d	$f14, pi_6
	mul.d	$f14, $f14, $f0
	l.d	$f12, zero
	l.d	$f16, zero
	jal	set_rotation
	jal	clear_screen
	jal	render
	la	$a0, test_file
	jal 	save_to_file
	addiu	$s2, $s2, 1
	b	test_rot_loop_y
test_rot_loop_y_end:
	li	$s2, 0
	li	$t1, 'Z'
	sb	$t1, test_file
test_rot_loop_z:
	beq	$s2, 12, test_rot_loop_z_end
	addiu	$t1, $s2, 'A'
	sb	$t1, test_file + 1
	
	mtc1.d	$s2, $f0
	cvt.d.w	$f0, $f0		
	
	l.d	$f16, pi_6
	mul.d	$f16, $f16, $f0
	l.d	$f12, zero
	l.d	$f14, zero
	jal	set_rotation
	jal	clear_screen
	jal	render
	la	$a0, test_file
	jal 	save_to_file
	addiu	$s2, $s2, 1
	b	test_rot_loop_z
test_rot_loop_z_end:
	li	$s2, 0
	li	$t1, 'B'
	sb	$t1, test_file
	
test_rot_loop_xyz:
	beq	$s2, 16, test_rot_loop_xyz_end
	addiu	$t1, $s2, 'A'
	sb	$t1, test_file + 1
	mtc1.d	$s2, $f0
	cvt.d.w	$f0, $f0		
	l.d	$f12, pi_8
	l.d	$f14, pi_8
	l.d	$f16, pi_8
	mul.d	$f12, $f12, $f0
	mul.d	$f14, $f14, $f0
	mul.d	$f16, $f16, $f0
	jal	set_rotation
	jal	render
	la	$a0, test_file
	jal 	save_to_file
	addiu	$s2, $s2, 1
	b	test_rot_loop_xyz
test_rot_loop_xyz_end:
	ret



