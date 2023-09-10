
## CONFIG

- motor
	- vangle (**type:** `number`): Motor vertical angle offset
	- hangle (**type:** `number`): Motor horizontal angle offset
	- velocity (**type:** `number`): Motor velocity
	- strength (**type:** `number`): Motor strength
	- index
		- hmotor (**type:** `number`) Vertical motor index
		- vmotor (**type:** `number`) Horizontal motor index
	- min_angle (**type:** `number`): Minimum permissible angle for motors
- target
	- position (**type:** `{x: number, y: number, z: number}`): The target position offset relative to the radar
	- velocity (**type:** `{x: number, y: number, z: number}`): The target velocity offset relative to the radar
	- acceleration (**type:** `{x: number, y: number, z: number}`): The target acceleration offset relative to the radar
- tracker
	- expiration_time (**type:** `number`): The time in seconds before the current target is considered lost
	- min_height (**type:** `number`): The minimum height of the target relative to the radar at which the target will be used
	- min_distance (**type:** `number`): The minimum target distance relative to the radar at which the target will be used
	- max_distance (**type:** `number`): The maximum target distance relative to the radar at which the target will be used
	- shutter_speed (**type:** `number`): The period in seconds between snapshots of the target position
	- mean
		- velocity (**type:** `number [0,1]`) The exponential moving average (EMA) velocity coefficient
		- acceleration (**type:** `number [0,1]`): The exponential moving average (EMA) acceleration coefficient
		- vangle (**type:** `number [0,1]`) The exponential moving average (EMA) vertical motor angle coefficient
		- hangle (**type:** `number [0,1]`) The exponential moving average (EMA) horizontal motor angle coefficient
- projectile
	- speed (**type:** `number`): The projectile speed used in calculations
	- acceleration (**type:** `number`): The absolute acceleration of the projectile used in calculations
- autolaunch
	<!--- - enable (**type:** `boolean`): Enable the autolaunch of the projectile --->
	<!--- - reload_time (**type:** `number`): Time in seconds of inactivity until the next launch --->
	- position_samples_number (**type:** `number`): The number of samples of the target position used in the calculation before the launch is ready (see: `shutter_speed`)
	- stabilization_time (**type:** `number`): The time in seconds before launch at which no actions will be performed
	- min_launch_vangle (**type:** `number`): The minimum vertical launch angle

## Build

- Variables
	- **pp_out**: Path to the preprocessed output file
	- **minify_out**: The path to the minified output file. *Only when using the `minify` target*
	- **lua**: The path to the `lua` executable
	- **clippath**: The path to the executable file that can pipe the passed string and save it to the clipboard
	- **build**: Scriptable Computer mod like this build for ("SC", "SCI")
	- **verbose**: Enable detailed mode for this build. It can also accept a table type and enable/disable individual detailed output. (**type:** `boolean` or `{*: nil or boolean}`). Examples: `true`, `false`, `{autolaunch=false}`, `{velocity=true,autolaunch=false}`, `{acceleration=true,velocity=true}`
		- **velocity** (`false`): Print velocity every time it is updated
		- **acceleration** (`false`): Print acceleration every time it is updated
		- **autolaunch** (`true`): The current status of the charge and the result of the launch
		- **calculate_aim** (`false`): Print all possible roots of the solved equation (even negative ones) and print the selected
		- **final_velocity** (`false`): Output the final velocity
		- **final_acceleration** (`false`): Output the final acceleration
	- **features**: Enable or disable some features. The list of features should start with `{` and end with `}`. It should contain a comma-separated list of feature names, then `=`, and after it should contain the feature status `true` or `false`. Examples: `{use_velocity=false}`, `{use_acceleration=true}`, `{use_velocity=false,use_acceleration=false}`
		- **use_velocity** (`true`): Use velocity in calculations
		- **use_acceleration** (`true`): Use acceleration in calculations
		- **manual** (`false`): Enable manual control
- Targets
	- **[default]**, **clip**: Preprocess, minify and copy to the clipboard (`clippath`)
	- **minify**: Preprocess, minify and save it to the file (`minify_out`)
	- **preprocess**: Only preprocess without minifying and save it to the file (`pp_out`)

```bash
# download submodules 'lua-minify' and 'LuaPreprocess'
$ git submodule update --init

# preprocess, minify and copy to the clipboard
$ make
$ make clip

# preprocess, minify and save it to the file (see: `minify_out`)
$ make minify
```

## Config Template

The file [config.template.lua](config.template.lua) contains a template for the config for the cannon. You can copy it to the [config.lua](config.lua) file and adjust parameters for yourself. See [Config](#config)
