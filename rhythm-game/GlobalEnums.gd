# This essentialy means PrecisionEnum will be available everywhere without the
# need for preload, meaning it should work for const and static func as well.
class_name GlobalEnums
enum Precision { Perfect, Good, Okay, Miss }
enum Testing { One, Two, Three }
enum CollisionMask{ Center = 1, Hit_Detect = 2 }
static var entered : int = 0
static var exited : int = 0
