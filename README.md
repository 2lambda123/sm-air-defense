
# CONFIG

- motor
	- vangle (**type:** `number`): Motor vertical angle offset
	- hangle (**type:** `number`): Motor horizontal angle offset
	- velocity (**type:** `number`): Motor velocity
	- strength (**type:** `number`): Motor strength
- tracker
	- expiration_time (**type:** `number`): The time in seconds before the current target is considered lost
	- min_height (**type:** `number`): The minimum height of the target relative to the radar at which the target will be used
	- min_distance (**type:** `number`): The minimum target distance relative to the radar at which the target will be used
	- max_distance (**type:** `number`): The maximum target distance relative to the radar at which the target will be used
	- merge_max_distance (**type:** `number`): If target A is at this distance relative to the targeted target B and if B is lost, then target A will be selected regardless of `expiration_time`
	- shutter_speed (**type:** `number`): The period in seconds between snapshots of the target position
- target
	- position (**type:** `vec3`): Target position offset
	- velocity (**type:** `vec3`): Target velocity offset
	- acceleration (**type:** `vec3`): Target acceleration offset
- projectile
	- speed (**type:** `number`): Projectile velocity used in calculations
	- acceleration (**type:** `number`): Projectile acceleration used in calculations
- autolaunch
	- enable (**type:** `boolean`): Enable the autolaunch of the projectile
	- aiming_time (**type:** `number`): The pointing time in seconds at which the shooting angle will be approximated
	- stabilization_time (**type:** `number`): The time in seconds before launch at which no actions will be performed
	- min_launch_vangle (**type:** `number`): Minimum vertical launch angle
	- min_aim_vangle (**type:** `number`): Minimum vertical aiming angle
