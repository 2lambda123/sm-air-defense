function cbrt(x)
	if x < 0 then return -((-x)^(1/3))
	else return (x)^(1/3) end
end
function solve_quadratic(a, b, c)
	local D = b^2 - 4*a*c
	if D > 0 then
		local sqrt_D = math.sqrt(D)
		return { (-b + sqrt_D) / (2*a), (-b - sqrt_D) / (2*a) }
	elseif D == 0 then
		return { -b/(2*a) }
	end
	return {}
end
function solve_cubic(a, b, c, d)
	if a == 0 then return solve_quadratic(b, c, d) end
	local p = (3*a*c - b^2) / (3*a^2)
	local q = (2*b^3 - 9*a*b*c + 27*a^2*d) / (27*a^3)
	local Q = p^3/27 + q^2/4
	local solutions
	if Q > 0 then
		solutions = { cbrt(-q/2 + math.sqrt(Q)) + cbrt(-q/2 - math.sqrt(Q)) }
	elseif Q == 0 then
		local u = cbrt(-q/2)
		solutions = { u*2, -u, -u }
	else
		local u = math.acos(3*q/(2*p)*math.sqrt(-3/p)) / 3
		local v = 2*math.sqrt(-p/3)
		solutions = { v*math.cos(u), v*math.cos(u - 2*math.pi/3), v*math.cos(u - 4*math.pi/3) }
	end
	for i=1,#solutions do
		solutions[i] = solutions[i] - b/(3*a)
	end
	return solutions
end
function solve_quartic(c0, c1, c2, c3, c4)
	if c0 == 0 then return solve_cubic(c1, c2, c3, c4) end
	local a, b, c, d = c1/c0, c2/c0, c3/c0, c4/c0
	local p = b - 3*a^2/8
	local q = a^3/8 - a*b/2 + c
	local r = -3*a^4/256 + a^2*b/16 - c*a/4 + d
	local s = solve_cubic(2, -p, -2*r, r*p - q^2/4)[1]

	if 2*s <= p then return {} end
	local u = math.sqrt(2*s - p)
	local v = q/(2*u)
	local solutions = solve_quadratic(1, -u, v + s)
	local solutions2 = solve_quadratic(1, u, -v + s)
	solutions[#solutions+1] = solutions2[1]
	solutions[#solutions+1] = solutions2[2]
	for i=1,#solutions do
		solutions[i] = solutions[i] - a/4
	end
	return solutions
end
function find_target_by(radar, filter_fn)
	for angle_mul=0,1 do
		radar.setAngle(angle_mul * math.pi)
		for _, v in pairs(radar.getTargets()) do
			if filter_fn(v) then
				return v
			end
		end
	end
	return nil
end

function get_radar()
	local radar = sci and sci.getRadars()[1] or getRadars()[1]
	radar.setHFov(math.pi)
	radar.setVFov(math.pi)
	return radar
end

function get_motor(index)
	index = index or 1
	local motor = sci and sci.getMotors()[index] or getMotors()[index]
	motor.setVelocity(CONFIG.motor.velocity)
	motor.setStrength(CONFIG.motor.strength)
	--motor.setAngle(0)
	motor.setActive(true)
	return motor
end

function polar_to_vec3(distance, hangle, vangle)
	local x = distance * math.cos(vangle) * math.cos(hangle)
	local y = distance * math.cos(vangle) * math.sin(hangle)
	local z = distance * math.sin(vangle)
	return sm.vec3.new(x, y, z)
end

function vec3_to_polar(vector)
	local distance = vector:length()
	local hangle = math.acos(vector.x / math.sqrt(vector.x^2 + vector.y^2)) * (vector.y < 0 and -1 or 1)
	local vangle = math.asin(vector.z / distance)
	return distance, hangle, vangle
end

function vec3_of_target(target)
	return polar_to_vec3(target[4], target[2], target[3])
end

function sort_positives(arr)
	table.sort(arr, function(a, b) return a > b end)
	for i = #arr,1,-1 do
		if arr[i] >= 0 then break end
		arr[i] = nil
	end
	table.sort(arr)
	return arr
end

function calculate_bullet_hit(position, velocity, acceleration, bullet_speed, bullet_acceleration)
	local c0 = (acceleration:dot(acceleration) - bullet_acceleration^2) / 4
	local c1 = velocity:dot(acceleration) - bullet_speed*bullet_acceleration
	local c2 = position:dot(acceleration) + velocity:dot(velocity) - bullet_speed^2
	local c3 = 2*position:dot(velocity)
	local c4 = position:dot(position)
	local solutions = solve_quartic(c0, c1, c2, c3, c4)

	return sort_positives(solutions)
end

function SMA_new(size, default)
	return {size = size, result = default or 0, index = 1, default = default or 0}
end
function SMA_commit(self, value)
	self.result = self.result + (value - (self[self.index] or self.default)) / self.size
	self[self.index] = value
	self.index = (self.index % self.size) + 1
	return self[self.index] == nil and value or self.result
end
function SMA_get(self) return self.result end

function CA_new(zero)
	return {n = 1, result = zero or 0}
end
function CA_commit(self, value)
	self.result = self.result + (value - self.result) / self.n
	self.n = self.n + 1
	return self.result
end
function CA_get(self) return self.result end

function EMA_new(smoothing_constant)
	return { alpha = smoothing_constant, result}
end
function EMA_commit(self, value)
	self.result = value * self.alpha + (self.result or value) * (1 - self.alpha)
	return self.result
end
function EMA_get(self) return self.result end
function EMA_set(self, value) self.result = value end

function DEMA_new(a)
	return { result, alpha = a, result_ema = EMA_new(a) }
end
function DEMA_commit(self, value)
	self.result = EMA_commit(self.result_ema, value) * self.alpha + (self.result or value) * (1 - self.alpha)
	return self.result
end
function DEMA_get(self) return self.result end

function TargetTracker_new()
	return {
		tracked_positions = {}, last_time = os.clock(),
		velocity_mean = EMA_new(2 / (4 + 1)), acceleration_mean = EMA_new(2 / (15 + 1))
	}
end
function TargetTracker_track(self, new_position)
	if os.clock() - self.last_time < CONFIG.tracker.shutter_speed then return end
	self.last_time = os.clock()

	self.tracked_positions[3] = self.tracked_positions[2]
	self.tracked_positions[2] = self.tracked_positions[1]
	self.tracked_positions[1] = new_position

	if #self.tracked_positions == 3 then
		TargetTracker_update(self)
	end
end
function TargetTracker_update(self)
	local p = self.tracked_positions
	local time = CONFIG.tracker.shutter_speed

	local vel2, vel1 = (p[2] - p[3]) / time, (p[1] - p[2]) / time
	local accel = (vel2 - vel1) / (time*2)

	if EMA_get(self.velocity_mean) ~= nil then
		EMA_set(self.velocity_mean, EMA_get(self.velocity_mean) + EMA_get(self.acceleration_mean)*time)
	end

	EMA_commit(self.velocity_mean, vel1)
	EMA_commit(self.acceleration_mean, accel)
end
function TargetTracker_velocity(self)
	return EMA_get(self.velocity_mean) or sm.vec3.zero()
end
function TargetTracker_acceleration(self)
	return EMA_get(self.acceleration_mean) or sm.vec3.zero()
end

function calculate_aim(position, velocity, acceleration)
	position = position + CONFIG.target.position
	velocity = velocity + CONFIG.target.velocity
	acceleration = acceleration + CONFIG.target.acceleration
	local t = calculate_bullet_hit(
		position, velocity, acceleration, CONFIG.projectile.speed, CONFIG.projectile.acceleration
	)[1]
	if t == nil then return nil end

	local next_position = position + velocity*t + acceleration*t^2/2
	local distance, hangle, vangle = vec3_to_polar(next_position)
	return distance, hangle, vangle
end

function StrongFindTargetState_new()
	return { time = -math.huge, find_fn }
end

function strong_find_target_by(state, radar, fn)
	if os.clock() - state.time > CONFIG.tracker.expiration_time then
		state.find_fn = function(v) return fn(v) end
		state.time = math.huge
	end
	local target = find_target_by(radar, state.find_fn)
	if target ~= nil then
		state.find_fn = function(v) return v[1] == target[1] and fn(v) end
		state.time = os.clock()
	else
		find_target_by(radar, function(v) return  end)
	end
	return target
end

function AutolaunchState_new()
	return { start_time = os.clock(), angles_mean = { hangle = DEMA_new(0.12), vangle = DEMA_new(0.12) } }
end
function autolaunch_start(state, aim_fn, launch_fn, new_hangle, new_vangle)
	local time_since = os.clock() - state.start_time
	local launch_time = CONFIG.autolaunch.launch_time

	if time_since >= launch_time + 1 then
		launch_fn(false)
	elseif time_since >= launch_time then
		local can_launch = CONFIG.autolaunch.min_launch_vangle <= DEMA_get(state.angles_mean.vangle) + CONFIG.motor.vangle
		launch_fn(can_launch)
	elseif time_since >= launch_time - CONFIG.autolaunch.stabilization_time then
		launch_fn(false)
		--print("DO NOTING")
	else
		--print("AIMING")
		launch_fn(false)
		local hangle = DEMA_commit(state.angles_mean.hangle, new_hangle)
		local vangle = DEMA_commit(state.angles_mean.vangle, new_vangle)
		if vangle >= CONFIG.autolaunch.min_aim_vangle then
			aim_fn(hangle, vangle)
		end
	end
end

CONFIG = CONFIG or {
	motor = {
		vangle = 0,
		hangle = -math.pi/2,
		velocity = 1,
		strength = 5000
	}, tracker = {
		expiration_time = 2,
		min_height = 0.5,
		min_distance = 8,
		max_distance = 350,
		merge_max_distance = 2,
		shutter_speed = 0.2
	}, target = {
		position = sm.vec3.new(28, 9, 4) / 4,
		velocity = sm.vec3.zero(),
		acceleration = sm.vec3.new(0, 0, 39.24) / 4
	}, projectile = {
		speed = 84,
		acceleration = 0
	}, autolaunch = {
		enable = true,
		--launch_time = 3.5,
		launch_time = 7,
		stabilization_time = 0.15,
		min_launch_vangle = math.rad(20),
		min_aim_vangle = math.rad(5)
	},
}

local radar = get_radar()
hmotor = hmotor or get_motor(1)
vmotor = vmotor or get_motor(2)

target_tracker = target_tracker or TargetTracker_new()

target_finder_state = target_finder_state or StrongFindTargetState_new()

local target = strong_find_target_by(target_finder_state, radar, function(v)
	return v[4] * math.sin(v[3]) >= CONFIG.tracker.min_height
		   and v[4] >= CONFIG.tracker.min_distance and v[4] <= CONFIG.tracker.max_distance
end)

if target == nil then
	if CONFIG.autolaunch.enable then
		autolaunch_state = nil
	end
else
	local recent_position = vec3_of_target(target)

	TargetTracker_track(target_tracker, recent_position)

	local target_velocity, target_acceleration = TargetTracker_velocity(target_tracker), TargetTracker_acceleration(target_tracker)
	local distance, hangle, vangle = calculate_aim(recent_position, target_velocity, target_acceleration)
	if distance == nil then return end

	if not CONFIG.autolaunch.enable then
		angles_sma = angles_sma or { hangle = SMA_new(40), vangle = SMA_new(40) }
		hmotor.setAngle(SMA_update(angles_sma.hangle, hangle) + CONFIG.motor.hangle)
		vmotor.setAngle(SMA_update(angles_sma.vangle, vangle) + CONFIG.motor.vangle)
	else
		autolaunch_state = autolaunch_state or AutolaunchState_new()
		local function launch_fn(cond) setreg("LAUNCH", cond) end
		local function aim_fn(hangle, vangle)
			hmotor.setAngle(hangle + CONFIG.motor.hangle)
			vmotor.setAngle(vangle + CONFIG.motor.vangle)
		end
		autolaunch_start(autolaunch_state, aim_fn, launch_fn, hangle, vangle)
		--print(math.floor((os.clock() - autolaunch_start_time - launch_time) * 100) / 100)
	end
end
