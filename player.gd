extends Node2D

var ball
var ball_launch
var gun
var gun_pos
var mouse_pos
var shoot_direction
var shoot_velocity
var shoot_velocity_scale
var shoot_velocity_scale_delta = .01
const shoot_velocity_max = 1000
var shoot_dir_v_max
const laser_color = Color(0, 1, 0, .4)
const laser_point_color = Color(0, 1, 0, .9)


func node_reset(name):
	var l = get_parent()
	if l.find_node(name):
		l.get_node(name).reset()


func reset():
	get_node("../bar").reset()
	node_reset('spring')
	shoot_direction = Vector2(0, -1)
	shoot_velocity = Vector2()
	shoot_velocity_scale = .04
	shoot_dir_v_max = shoot_velocity_max*shoot_direction
	mouse_pos = gun_pos
	gun.set_rot(0)
	update()
	if is_a_parent_of(ball):
		remove_child(ball)
	get_tree().set_pause(false)
	set_process_input(true)


func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ball = preload("res://ball.scn").instance()
	gun = get_node("../gun")
	gun_pos = gun.get_pos()
	gun.get_node("inside").connect("body_enter", self, "_on_gun_body_enter")
	gun.get_node("inside").connect("body_exit", self, "_on_gun_body_exit")
	reset()


func _on_gun_body_enter(body):
	if ball_launch:
		set_process(true)


func _on_gun_body_exit(body):
	if body.get_name()=="ball":
		ball_launch = true
		set_process(false)


func _process(delta):
	if ball.get_linear_velocity().length()<10:
		remove_child(ball)
		set_process_input(true)


func _fixed_process(delta):
	if shoot_velocity_scale>1 or shoot_velocity_scale<.04:
		shoot_velocity_scale_delta = -shoot_velocity_scale_delta
	shoot_velocity_scale += 100*delta*shoot_velocity_scale_delta
	shoot_velocity = shoot_velocity_scale*shoot_dir_v_max
	update()


func _input(e):
	if e.type==InputEvent.MOUSE_MOTION:
		mouse_pos = e.pos - get_parent().get_pos()
		var angle = (gun_pos - mouse_pos).angle()
		if angle>-PI/2 and angle<PI/2:
			gun.set_rot(angle)
			shoot_direction = (mouse_pos - gun_pos).normalized()
			shoot_dir_v_max = shoot_velocity_max*shoot_direction
			update()
	
	elif e.type==InputEvent.MOUSE_BUTTON:
		if e.pressed:
			set_fixed_process(true)
		else:
			set_fixed_process(false)
			ball_launch = false
			add_child(ball)
			ball.set_pos(gun_pos + 25*shoot_direction)
			ball.set_linear_velocity(shoot_velocity)
			set_process_input(false)
			update()


func _draw():
	var level_global_pos = get_parent().get_pos()
	# Draw laser
	var laser_begin_pos = gun_pos + 56*shoot_direction + level_global_pos
	# 800 == get_viewport_rect().size.width * sqrt(2)
	var laser_end_pos = gun_pos + 800*shoot_direction + level_global_pos
	var space_state = get_world_2d().get_direct_space_state()
	var r = space_state.intersect_ray(laser_begin_pos, laser_end_pos, [gun])
	if r.has("position"):
		laser_end_pos = r.position
	laser_begin_pos -= level_global_pos
	laser_end_pos -= level_global_pos
	draw_circle(laser_end_pos, 2, laser_point_color)
	draw_line(laser_begin_pos, laser_end_pos, laser_color)
	# Draw velocity indicator
	draw_set_transform(gun_pos, shoot_direction.angle(), Vector2(1,1))
	var h = (int(49*shoot_velocity_scale) / 6) * 6
	var rec = Rect2(-6, 0, 12, h)
	var rec_src = Rect2(0, 0, 12, h)
	draw_texture_rect_region(preload("res://textures/indicator.png"), rec, rec_src)


func _on_ball_outside(body):
	get_tree().set_pause(true)
	get_node("../..").call_deferred('next_level')
