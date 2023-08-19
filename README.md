
# CONFIG

- motor
	- vangle (**type:** `number`): The motor vertical angle offset
	- hangle (**type:** `number`): The motor horizontal angle offset
	- velocity (**type:** `number`): The motor velocity
	- strength (**type:** `number`): The motor strength
- tracker
	- expiration_time (**type:** `number`): The time in seconds before the current target is considered lost
	- min_height (**type:** `number`): The minimum height of the target relative to the radar at which the target will be used
	- min_distance (**type:** `number`): The minimum target distance relative to the radar at which the target will be used
	- max_distance (**type:** `number`): The maximum target distance relative to the radar at which the target will be used
	- shutter_speed (**type:** `number`): The period in seconds between snapshots of the target position
- target
	- position (**type:** `vec3`): The target position offset relative to the radar
	- velocity (**type:** `vec3`): The target velocity offset relative to the radar
	- acceleration (**type:** `vec3`): The target acceleration offset relative to the radar
- projectile
	- speed (**type:** `number`): The projectile speed used in calculations
	- acceleration (**type:** `number`): The absolute acceleration of the projectile used in calculations
- autolaunch
	- enable (**type:** `boolean`): Enable the autolaunch of the projectile
	- aiming_time (**type:** `number`): The pointing time in seconds at which the shooting angle will be approximated
	- stabilization_time (**type:** `number`): The time in seconds before launch at which no actions will be performed
	- min_launch_vangle (**type:** `number`): The minimum vertical launch angle
	- min_aim_vangle (**type:** `number`): The minimum vertical aiming angle
