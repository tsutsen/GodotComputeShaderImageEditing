extends TextureRect

# IMAGE VARIABLES
# any image can be dragged/assigned to texture of this TextureRect
# you can try different images from sample_images folder
@onready var image : Image = texture.get_image()
@onready var image_size : Vector2 = image.get_size()
@export var image_format := Image.FORMAT_RGBAF

# SHADER VARIABLES
@export_file("*.glsl") var shader_path : String = "res://light_adjustments.glsl"
var texture_compute_shader : ComputeHelper
var texture_shader_groups : Vector3i
var input_texture : ImageUniform
var output_texture : ImageUniform
var texture_parameters_buffer : StorageBufferUniform
var shader_params = [0.0, 0.0]

func _ready():
	# to safely access rendering internals, it is better to call functions this way
	RenderingServer.call_on_render_thread(init_shader)

func init_shader():
	# convert image to the specified format
	image.convert(image_format)
	image_size = image.get_size() 

	# assign Texture2DRD to current texture so that its data could be synced with data on GPU
	texture = Texture2DRD.new()
	
	# init shader and shader pipeline
	texture_compute_shader = ComputeHelper.create(shader_path)
	
	# init image uniforms
	input_texture = ImageUniform.create(image)
	output_texture = ImageUniform.create(image)
	# link current TextureRect texture to output_texture by assigning equal IDs
	# all changes made to output_texture uniform will be displayed in this TextureRect
	texture.texture_rd_rid = output_texture.texture
	
	# calculate number of work groups
	var x_groups = (image_size.x - 1) / 8 + 1
	var y_groups = (image_size.y - 1) / 8 + 1
	var z_groups = 1
	texture_shader_groups = Vector3i(x_groups, y_groups, z_groups)
	
	# init empty buffer for shader parameters
	texture_parameters_buffer = StorageBufferUniform.create(PackedFloat32Array([0.0]).to_byte_array())
	
	# add uniforms to shader pipeline
	texture_compute_shader.add_uniform_array([texture_parameters_buffer, input_texture, output_texture])


func update_shader(shader_params):
	# send shader_params to shader
	texture_parameters_buffer.update_data(PackedFloat32Array(shader_params).to_byte_array())
	# execute shader
	texture_compute_shader.run(texture_shader_groups)


func _on_brightness_slider_value_changed(value):
	# change first value in shader_params array (brightness)
	shader_params[0] = value
	# execute shader
	update_shader(shader_params)


func _on_contrast_slider_value_changed(value):
	# change second value in shader_params array (contrast)
	shader_params[1] = value
	# execute shader
	update_shader(shader_params)
