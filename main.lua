
!(
PPDEFS = require("ppdefs")

BUILD = PPDEFS.BUILD
VERBOSE = PPDEFS.VERBOSE
FEATURES = PPDEFS.FEATURES or {}

assert(type(VERBOSE) == 'boolean' or type(VERBOSE) == 'table', "'VERBOSE' must have a 'table' type or a 'boolean' type")
assert(type(FEATURES) == 'nil' or type(FEATURES) == 'table', "'FEATURES' must have a 'table' type or a 'nil' type")

function get_feature(name, default)
	if FEATURES[name] == nil then return default end
	return FEATURES[name]
end
function get_verbose_feature(name, default)
	if type(VERBOSE) ~= 'table' then
		if VERBOSE == false then return false end
		return default
	end
	if VERBOSE[name] == nil then return default end
	return VERBOSE[name]
end

USE_VELOCITY     = get_feature('use_velocity', true)
USE_ACCELERATION = get_feature('use_acceleration', true)

VERBOSE_VELOCITY           = get_verbose_feature('velocity', false)
VERBOSE_ACCELERATION       = get_verbose_feature('acceleration', false)
VERBOSE_AUTOLAUNCH         = get_verbose_feature('autolaunch', true)
VERBOSE_CALCULATE_AIM      = get_verbose_feature('calculate_aim', false)
VERBOSE_FINAL_VELOCITY     = get_verbose_feature('final_velocity', false)
VERBOSE_FINAL_ACCELERATION = get_verbose_feature('final_acceleration', false)

function sqr_dot(vec)
	return ([[%s:dot(%s)]]):format(vec, vec)
end
function dot(vec1, vec2)
	return ([[%s:dot(%s)]]):format(vec1, vec2)
end
function sgn(x)
	return ([[(%s < 0 and -1 or 1)]]):format(x)
end

function setreg(reg, value)
	return ([[%s(%s,%s)]]):format(BUILD == 'SCI' and 'sci.setreg' or 'setreg', reg, value)
end
function getreg(reg)
	return ([[(%s(%s) == 1)]]):format(BUILD == 'SCI' and 'sci.getreg' or 'getreg', reg)
end
function getRadars()
	return BUILD == 'SCI' and 'sci.getRadars()' or 'getRadars()'
end
function getMotors()
	return BUILD == 'SCI' and 'sci.getMotors()' or 'getMotors()'
end
function getCameras()
	return BUILD == 'SCI' and 'sci.getCameras()' or 'getCameras()'
end
function hmotor_setAngle(motor, angle)
	return ([[%s.setAngle(%s+%s)]]):format(motor, angle, CONFIG.motor.hangle)
end
function vmotor_setAngle(motor, angle)
	return ([[
		if %s >= %s then %s.setAngle(%s+%s) end
	]]):format(angle, CONFIG.motor.min_vangle + CONFIG.motor.vangle, motor, angle, CONFIG.motor.vangle)
end
function table_to_vec3(x)
	if x == "{0,0,0}" then
		return [[sm.vec3.zero()]]
	end
	return ([[sm.vec3.new(%s)]]):format(x:sub(2, -2))
end
function pp_unpack(x, n)
	n = tonumber(n)
	for i=1,n do
		outputLua(('%s[%s]%s'):format(x, i, (i < n and ',' or '')))
	end
end
function pp_append(dest, src, max_size)
	for i=1,max_size do
		outputLua(('%s[#%s+1]=%s[%s]\n'):format(dest, dest, src, i))
	end
end
function file_exists(name)
	local f = io.open(name, 'r')
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

if not file_exists("config.lua") then
	io.stderr:write("ERROR: the config file 'config.lua' was not found. You can create it using the template file 'config.template.lua'\n")
	os.exit(1)
end

CONFIG = require("config")
)
sqrt, sin, cos, pi, acos, asin = math.sqrt, math.sin, math.cos, math.pi, math.acos, math.asin

function cbrt(x)
	if x < 0 then return -((-x)^(1/3))
	else return (x)^(1/3) end
end
function solve_quadratic(a, b, c)
	local D = b^2 - 4*a*c
	if D > 0 then
		local sqrt_D = sqrt(D)
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
		solutions = { cbrt(-q/2 + sqrt(Q)) + cbrt(-q/2 - sqrt(Q)) }
	elseif Q == 0 then
		local u = cbrt(-q/2)
		solutions = { u*2, -u, -u }
	else
		local u = acos(3*q/(2*p)*sqrt(-3/p)) / 3
		local v = 2*sqrt(-p/3)
		solutions = { v*cos(u), v*cos(u - 2*pi/3), v*cos(u - 4*pi/3) }
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
	local u = sqrt(2*s - p)
	local v = q/(2*u)
	local solutions = solve_quadratic(1, -u, v + s)
	local solutions2 = solve_quadratic(1, u, -v + s)
	@@pp_append(solutions, solutions2, 2)
	for i=1,#solutions do
		solutions[i] = solutions[i] - a/4
	end
	return solutions
end
function find_target(radar, filter_fn)
	-- targets structure { [1] = id, [2] = hangle, [3] = vangle, [4] = distance, [5] = force }
	!for _, angle in pairs({0, math.pi}) do
		radar.setAngle(!(angle))
		local targets = radar.getTargets()
		for i=1,#targets do
			if filter_fn(targets[i]) then
				return targets[i]
			end
		end
	!end
	return nil
end

function get_radar()
	local radar = @@getRadars()[1]
	radar.setHFov(pi)
	radar.setVFov(pi)
	return radar
end

function get_motor(index, default_angle)
	local motor = @@getMotors()[index]
	motor.setVelocity(!(CONFIG.motor.velocity))
	motor.setStrength(!(CONFIG.motor.strength))
	motor.setAngle(default_angle)
	motor.setActive(true)
	return motor
end

function polar_to_vec3(distance, hangle, vangle)
	local cos_vangle = cos(vangle)
	local x = distance * cos_vangle * cos(hangle)
	local y = distance * cos_vangle * sin(hangle)
	local z = distance * sin(vangle)
	return sm.vec3.new(x, y, z)
end

function vec3_to_polar(vector)
	local distance = vector:length()
	local hangle = acos(vector.x / sqrt(vector.x^2 + vector.y^2)) * @@sgn(vector.y)
	local vangle = asin(vector.z / distance)
	return distance, hangle, vangle
end

!(
function vec3_of_target(target)
	return ([[polar_to_vec3(%s[4], %s[2], %s[3])]]):format(target, target, target)
end
)

function dist_between_targets(target1, target2)
	local r1, h1, v1, r2, h2, v2 = target1[4], target1[2], target1[3], target2[4], target2[2], target2[3]
	return sqrt(r1^2 + r2^2 - 2*r1*r2*(cos(v1)*cos(v2)*cos(h1 - h2) + sin(v1)*sin(v2)))
end

function calculate_bullet_hit(position, velocity, acceleration, bullet_speed, bullet_acceleration)
	local c0 = (@@sqr_dot(acceleration) - bullet_acceleration^2) / 4
	local c1 = @@dot(velocity, acceleration) - bullet_speed*bullet_acceleration
	local c2 = @@dot(position, acceleration) + @@sqr_dot(velocity) - bullet_speed^2
	local c3 = @@dot(position, velocity)*2
	local c4 = @@sqr_dot(position)
	return solve_quartic(c0, c1, c2, c3, c4)
end

function SMA_new(size, default)
	return {size = size, result = default or 0, index = 1, default = default or 0}
end
function SMA_update(self, value)
	self.result = self.result + (value - (self[self.index] or self.default)) / self.size
	self[self.index] = value
	self.index = (self.index % self.size) + 1
	return self[self.index] == nil and value or self.result
end
function SMA_get(self) return self.result end

function CA_new(zero)
	return {n = 1, result = zero or 0}
end
function CA_update(self, value)
	self.result = self.result + (value - self.result) / self.n
	self.n = self.n + 1
	return self.result
end
function CA_get(self) return self.result end


!(
function EMA_new()
	return ([[{ result }]])
end
function EMA_update(self, value, alpha)
	return ([[
		%s.result = %s * %s + (%s.result or %s) * %s
	]]):format(self, value, alpha, self, value, 1 - alpha)
end
function EMA_get(self) return ([[%s.result]]):format(self) end
function EMA_set(self, value) return ([[%s.result = %s]]):format(self, value) end
)

!(
function TargetTracker_new()
	return ([[{
		tracked_positions = {}, tracked_times = {}, last_time = -math.huge,
		velocity_mean = %s, acceleration_mean = %s,
		samples_count = 0
	}]]):format(EMA_new(), EMA_new())
end
)
function TargetTracker_track(self, target, new_position)
	if os.clock() - self.last_time < !(CONFIG.tracker.shutter_speed) then return end

	self.last_time = os.clock()
	self.samples_count = self.samples_count + 1

	self.tracked_positions[3] = self.tracked_positions[2]
	self.tracked_positions[2] = self.tracked_positions[1]
	self.tracked_positions[1] = new_position

	self.tracked_times[3] = self.tracked_times[2]
	self.tracked_times[2] = self.tracked_times[1]
	self.tracked_times[1] = os.clock()

	if #self.tracked_positions == 3 then
		TargetTracker_update(self)
	end
end
function TargetTracker_update(self)
	local p1, p2, p3 = @@pp_unpack(self.tracked_positions, 3)
	local t1, t2, t3 = @@pp_unpack(self.tracked_times, 3)

	local v2, v1 = (p2 - p3) / (t2 - t3), (p1 - p2) / (t1 - t2)
	local accel = (v2 - v1) / (t1 - t3)

	!if USE_VELOCITY then
		@@EMA_update(self.velocity_mean, v1, !(CONFIG.tracker.mean.velocity))
		!if VERBOSE_VELOCITY then
			print('@'..self.samples_count, 'velocity:', @@EMA_get(self.velocity_mean))
		!end
	!end
	!if USE_ACCELERATION then
		@@EMA_update(self.acceleration_mean, accel, !(CONFIG.tracker.mean.acceleration))
		!if VERBOSE_ACCELERATION then
			print('@'..self.samples_count, 'acceleration:', @@EMA_get(self.acceleration_mean))
		!end
	!end
end
!(
function TargetTracker_velocity(self)
	return ([[(%s or sm.vec3.zero())]]):format(EMA_get(self..'.velocity_mean'), self)
end
function TargetTracker_acceleration(self)
	return ([[(%s or sm.vec3.zero())]]):format(EMA_get(self..'.acceleration_mean'), self)
end
function TargetTracker_samples_number(self)
	return ([[%s.samples_count]]):format(self)
end
)
function find_smallest_positive(list)
	local min = math.huge
	for _, val in pairs(list) do
		if val >= 0 and val < min then
			min = val
		end
	end
	return min
end

function calculate_aim(position, velocity, acceleration)
	position = position + @@table_to_vec3(!(CONFIG.target.position))
	velocity = velocity + @@table_to_vec3(!(CONFIG.target.velocity))
	acceleration = acceleration + @@table_to_vec3(!(CONFIG.target.acceleration))
	local solutions = calculate_bullet_hit(
		position, velocity, acceleration, !(CONFIG.projectile.speed), !(CONFIG.projectile.acceleration)
	)
	local t = find_smallest_positive(solutions)
	!if VERBOSE_CALCULATE_AIM then
		for i, v in ipairs(solutions) do
			print(i..':', v)
		end
		print("get:", t)
	!end
	if t == math.huge then return nil end

	local next_position = position + velocity*t + acceleration*t^2/2
	local distance, hangle, vangle = vec3_to_polar(next_position)
	return distance, hangle, vangle
end

!(
function SmartFindTargetState_new(on_new_find)
	return ([[{ time = -math.huge, find_fn, on_new_find = %s }]]):format(on_new_find)
end
)

function smart_find_target(state, radar, fn)
	if os.clock() - state.time > !(CONFIG.tracker.expiration_time) then
		state.find_fn = function(v) return fn(v) end
		state.time = math.huge
		state.on_new_find()
	end
	local target = find_target(radar, state.find_fn)

	if target ~= nil then
		state.find_fn = function (v) return v[1] == target[1] and fn(v) end
		state.time = os.clock()
	end
	return target
end

local radar = get_radar()
hmotor = hmotor or get_motor(!(CONFIG.motor.index.hmotor), 0)
vmotor = vmotor or get_motor(!(CONFIG.motor.index.vmotor), !(CONFIG.motor.min_vangle))

target_finder_state = target_finder_state or @@SmartFindTargetState_new(function()
	target_tracker = @@TargetTracker_new()
	!if CONFIG.autolaunch.enable then
		autolaunch_state = nil
	!end
end)

local target = smart_find_target(target_finder_state, radar, function(v)
	return v[4] * sin(v[3]) >= !(CONFIG.tracker.min_height) and v[4] >= !(CONFIG.tracker.min_distance) and v[4] <= !(CONFIG.tracker.max_distance)
end)

if target ~= nil then
	local recent_position = @@vec3_of_target(target)

	TargetTracker_track(target_tracker, target, recent_position)
	local target_velocity, target_acceleration = @@TargetTracker_velocity(target_tracker), @@TargetTracker_acceleration(target_tracker)
	local distance, hangle, vangle = calculate_aim(recent_position, target_velocity, target_acceleration)
	if distance == nil then return end

	!if not CONFIG.autolaunch.enable then
		angles_sma = angles_sma or { hangle = SMA_new(40), vangle = SMA_new(40) }
		local sma_hangle, sma_vangle = SMA_update(angles_sma.hangle, hangle), SMA_update(angles_sma.vangle, vangle)
		@@hmotor_setAngle(hmotor, sma_hangle)
		@@vmotor_setAngle(vmotor, sma_vangle)
	!else
		autolaunch_state = autolaunch_state or { start_time = math.huge }

		local time_since = os.clock() - autolaunch_state.start_time
		local position_samples = @@TargetTracker_samples_number(target_tracker)
		!local required_samples_number = CONFIG.autolaunch.position_samples_number
		if time_since >= !(CONFIG.autolaunch.stabilization_time + CONFIG.autolaunch.reload_time + 1) then
			target_finder_state = nil
		elseif time_since >= !(CONFIG.autolaunch.stabilization_time + 1) then
			@@setreg("LAUNCH", false)
		elseif time_since >= !(CONFIG.autolaunch.stabilization_time) then
			local can_launch = !(CONFIG.autolaunch.min_launch_vangle - CONFIG.motor.vangle) <= vangle
			!if VERBOSE_AUTOLAUNCH then
				if not verbose_autolaunch_print_state then
					if not @@getreg('ALLOW_LAUNCH') then
						print("NOT ALLOWED TO LAUNCH")
					elseif not can_launch then
						print("CANNOT LAUNCH")
					else
						print("LAUNCHING")
					end
				end
				verbose_autolaunch_print_state = true
			!end
			if can_launch and @@getreg('ALLOW_LAUNCH') then
				@@setreg("LAUNCH", true)
end
		elseif time_since >= 0 then
		elseif position_samples == !(required_samples_number) then
			!if VERBOSE_FINAL_VELOCITY and USE_VELOCITY then
				print('final velocity:', target_velocity)
			!end
			!if VERBOSE_FINAL_ACCELERATION and USE_ACCELERATION then
				print('final acceleration:', target_acceleration)
			!end
			autolaunch_state.start_time = os.clock()
		else
			@@setreg("LAUNCH", false)
			@@hmotor_setAngle(hmotor, hangle)
			@@vmotor_setAngle(vmotor, vangle)
			!if VERBOSE_AUTOLAUNCH then
				print(('[%d/%d] (%d%%)'):format(position_samples, !(required_samples_number), 100 * position_samples / !(required_samples_number)))
			!end
		end
	!end
end
