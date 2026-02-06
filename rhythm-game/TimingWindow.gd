class_name TimingWindow

## https://osu.ppy.sh/wiki/en/Gameplay/Judgement/osu%21mania

## ------------------------------------------------------------
##
## 					Timing Window Variables
##
## ------------------------------------------------------------

## A list of variables that control the Max hit error, much of which
## is inspired by osu!mania's judement system.

## A quick rundown, will give the following:
## PERFECT: +-016 ms 
## GREAT  : +-064 - 3 * OD ms 
## GOOD   : +-097 - 2 * OD ms
## OK     : +-127 - 2 * OD ms
## MEH    : +-151 - 3 * OD ms
## MISS   : +-188 - 3 * OD ms
static var OD 		: int = 0
static var timing_windows : Array[ int ] = [ 16, 97, 127, 151, 188 ]
const DIFFICULTY_CONST : Array[ int ] = [ 0, 3, 2, 2, 3, 3 ]

enum Precision { Perfect, Great, Okay, Meh, Miss, Out }
const TIMINGS : int = int( Precision.Out )
## Reverse Mapping
const INT_TO_PRECISION_ENUM : Array[ Precision ] = [ 
	Precision.Perfect, Precision.Great, Precision.Okay, Precision.Meh, Precision.Miss, Precision.Out ]

static func set_OD( overall_difficulty_multiplier : int ) -> void:
	OD = overall_difficulty_multiplier

static func set_timing_window( precision : Precision, timing_ms : int ) -> void:
	assert( precision != Precision.Out, "Precision range outside of Miss doesn't exist." )
	timing_windows[ int(precision) ] = timing_ms

static func get_timing_window( precision : Precision ) -> int:
	assert( precision != Precision.Out, "Precision range outside of Miss doesn't exist." )
	var idx : int = int( precision )
	return get_timing_window_idx( idx )

static func get_timing_window_idx( precision_idx : int ) -> int:
	assert( INT_TO_PRECISION_ENUM[ precision_idx ] != Precision.Out, "Precision range outside of Miss doesn't exist." )
	return timing_windows[ precision_idx ] - DIFFICULTY_CONST[ precision_idx ] * OD


## Returns the first timing_window that is not less than timing_deviation. For example, suppose OD == 0.
## If timing_deviation == 96, the first timing window not less than 96 is GREAT == 97. Hence, it will return 97.
## This is useful since if timing_deviation is greater than MISS == 188 (i.e. timing_deviation > 188), then it returns
## the final Out timing window. Hence this is useful for determining range of values dependent on the timing window function.
static func lower_bound(  timing_deviation : int, beg_idx : int, end_idx : int ) -> Precision:
	if ( beg_idx == end_idx ):
		return INT_TO_PRECISION_ENUM[ beg_idx ]

	var idx : int = beg_idx + ( (end_idx - beg_idx) >> 1 )
	var timing_window : int = get_timing_window_idx( idx )
	if ( timing_window < timing_deviation ): ## Mid < val
		beg_idx = idx + 1
	else: ## Mid >= val
		end_idx = idx
	return lower_bound( timing_deviation, beg_idx, end_idx )

## Main Function used to get the kind of precision that is expected
static func get_precision_of_timing_window_ceiling( timing_deviation : int ) -> Precision:
	assert( 0 <= timing_deviation, "Timing deviation needs to be a positive number" )
	return lower_bound( timing_deviation, int(Precision.Perfect), int(Precision.Out) )

## This will include the possiblity of floats, which will implicily floor it 
static func get_precision_of_timing_window( timing_deviation : float ) -> Precision:
	var rounded_up : int = ceil( timing_deviation )
	return get_precision_of_timing_window_ceiling( rounded_up )

static func verify_boundaries_of_timing_windows( ) -> void:
	var save_timing_windows : Array[ int ] = timing_windows
	var save_overall_difficult : int = OD

	timing_windows = [ 10, 20, 30, 40, 50 ]
	var lower : int = 0
	
	## Sweeps through each integer value within timing_windows, based on the lower 
	for idx in range( timing_windows.size( ) ):
		var upper : int = timing_windows[ idx ]
		for timing_window in range( lower, upper + 1 ):
			# print( "Testing timing Window: ", timing_window, " on precision zone: ", INT_TO_PRECISION_ENUM[ idx ] )
			assert( get_precision_of_timing_window_ceiling(timing_window) == INT_TO_PRECISION_ENUM[idx], "Timing Window is off" )
		lower = upper + 1

	## Test the boundaries from the boundary between Ok and Out.
	for timing_window in range( lower, lower + 10 ):
		# print( "Testing timing Window: ", timing_window, " on precision zone: ", Precision.Out )
		assert( get_precision_of_timing_window_ceiling( timing_window ) == Precision.Out )

	timing_windows = save_timing_windows
	OD = save_overall_difficult
