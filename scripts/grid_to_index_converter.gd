
class_name GridToIndex


static func to_index (grid_pos_ :Vector2i) -> String:

    var width = 20    
    var height = 32
    var width_zero :int = 'A'.unicode_at(0)
    var height_zero :int = 1
    
    var rel_grid_pos = grid_pos_ + Vector2i(width/2, height/2)
    

    return "(%s, %s)" %[String.chr(width_zero + rel_grid_pos.x), str(height_zero + rel_grid_pos.y)]



static func to_grid (index :String) -> Vector2i:
    return Vector2i.ZERO
