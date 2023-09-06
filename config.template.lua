return {
	motor = {
		vangle = 0,
		hangle = math.pi/2,
		velocity = 1,
		strength = 5000,
		index = { hmotor = 1, vmotor = 2 },
		min_vangle = math.rad(10),
	},
	target = {
		position = {-5.25, -0.25, -0.25},
		velocity = {0, 0, 0},
		acceleration = {0, 0, 10},
	},
	tracker = {
		expiration_time = 2,
		min_height = 1,
		min_distance = 8,
		max_distance = 250,
		shutter_speed = 0.2,
		mean = { velocity = 2 / (10 + 1), acceleration = 2 / (15 + 1) },
	},
	projectile = {
		speed = 99.8,
		acceleration = -19,
	},
	autolaunch = {
		position_samples_number = 20,
		stabilization_time = 0.2,
		min_launch_vangle = math.rad(20),
	},
}