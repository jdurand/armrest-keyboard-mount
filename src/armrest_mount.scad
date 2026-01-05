// Split Keyboard Armrest Mount - Slide-on insert with palm rest and mount cavity
// -------------------------------------------------

/* [Armrest Dimensions] */
arm_width = 96.0;
arm_thickness = 24.8;
lip_width = 5.0;       // Grip under the armrest
fit_tolerance = 0.5;   // Extra gap for sliding fit

/* [Ergonomics] */
tenting_angle = 15;      // 15 degrees tilt (Left/Right)
is_right_armrest = true; // TRUE = Right Arm (Left=High, Right=Low)

/* [Mount Configuration] */
wall_thickness = 4;     // Solid walls
mount_length = 100;     // Total length
top_wall_min = 6.0;     // Roof thickness
bottom_wall_slot = 4.0; // Floor thickness below slot

/* [Comfort Settings] */
rounding_r = 1.5;       // 1.5mm global rounding radius (Softens all edges)
dish_depth = 2.0;       // Visible depth
dish_radius = 75.0;     // Gentle curve
dish_offset_x = 38.0;   // Positioned on the lower side

/* [Ugreen MagSafe Cavity] */
magsafe_slot_width = 85.2;
magsafe_slot_thickness = 5.0; // Increased to 5mm for rubber feet
magsafe_slot_depth = 75.0;

/* [Preview] */
preview_context = true;
$fn = 40; // Reduced slightly for faster Minkowski preview

// -------------------------------------------------

// Calculate Geometry
rotation_val = is_right_armrest ? -tenting_angle : tenting_angle;
block_width = arm_width + 2*wall_thickness + fit_tolerance;

// Height Geometry (Slot)
slot_half_w = magsafe_slot_width / 2;
slot_half_t = magsafe_slot_thickness / 2;
slot_bbox_h = (magsafe_slot_width * abs(sin(rotation_val))) + (magsafe_slot_thickness * abs(cos(rotation_val)));

// Center height
center_h = bottom_wall_slot + slot_bbox_h/2 + top_wall_min;

// Wedge Heights
rise = (block_width/2) * tan(abs(rotation_val));
h_high = center_h + rise + 5;
h_low  = center_h - rise + 5;
h_left  = is_right_armrest ? h_high : h_low;
h_right = is_right_armrest ? h_low : h_high;
h_left_safe = max(h_left, 1);
h_right_safe = max(h_right, 1);

// Dish Height Calculation
slope_m = (h_right_safe - h_left_safe) / block_width;
surface_y_at_dish = h_left_safe + slope_m * (dish_offset_x + block_width/2);
sphere_y = surface_y_at_dish + dish_radius - dish_depth;


// -------------------------------------------------
// MAIN ASSEMBLY
// -------------------------------------------------

difference() {
  // 1. POSITIVE BODY (The Solid Block)
  // We apply Minkowski here to round ALL outer edges (Sides + Front + Back)
  minkowski() {
    union() {
      // A. Clamp Base Solid (Outer shell only)
      linear_extrude(height = mount_length - 2*rounding_r) // Shrink Z to account for expansion
        translate([0,0])
        clamp_outer_profile(rounding_r); // Shrink XY profile to account for expansion

      // B. Wedge Solid
      translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
        linear_extrude(height = mount_length - 2*rounding_r)
          wedge_profile_shrunk(rotation_val, block_width, rounding_r);
    }
    // The Rounding Tool
    sphere(r=rounding_r, $fn=12);
  }

  // 2. NEGATIVE CUTS (Performed AFTER rounding to maintain precision)

  // A. The Armrest Channel (Inner Void)
  // Must be long enough to cut through the rounded ends
  translate([0, 0, -5])
    linear_extrude(height = mount_length + 20)
      clamp_inner_cut_profile();

  // B. The Comfort Dish
  translate([dish_offset_x, sphere_y, 0])
    sphere(r=dish_radius);

  // C. The MagSafe Slot
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length - magsafe_slot_depth/2 + 0.1])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 1], center=true);

  // D. Front Opening Cleanup
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length + 5])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, 20], center=true);
}


// -------------------------------------------------
// MODULES
// -------------------------------------------------

// 1. Outer Shell Profile (Shrunk by r to maintain size after Minkowski)
module clamp_outer_profile(r) {
  w_outer = arm_width + (wall_thickness * 2) + fit_tolerance - 2*r;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance - 2*r;

  // Shifted back to 0,0 center relative to the grown object
  // Note: Minkowski adds 'r' in all directions.
  translate([-w_outer/2, -h_outer/2])
    square([w_outer, h_outer]);
}

// 2. Wedge Profile (Shrunk)
module wedge_profile_shrunk(angle, w, r) {
  // We simply offset the polygon inward by r
  offset(r = -r)
  polygon(points=[
    [-w/2, 0],
    [w/2, 0],
    [w/2, h_right_safe],
    [-w/2, h_left_safe]
  ]);
}

// 3. The Cutting Profile (The Void) - Exact Dimensions
module clamp_inner_cut_profile() {
  w_outer = arm_width + (wall_thickness * 2) + fit_tolerance;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance;
  w_inner = arm_width + fit_tolerance;
  h_inner = arm_thickness + fit_tolerance;

  // The inner box
  translate([-w_inner/2, -h_inner/2])
    square([w_inner, h_inner]);

  // The bottom gap
  gap_width = w_inner - (2 * lip_width);
  cut_height = wall_thickness + 10; // Tall enough to cut through bottom wall

  translate([-gap_width/2, -h_outer/2 - 5])
    square([gap_width, cut_height]);
}

// -------------------------------------------------
// PREVIEW
// -------------------------------------------------
if (preview_context) {
  // Ghost Armrest
  %color("Silver", 0.4)
  translate([-(arm_width)/2, -(arm_thickness)/2, -10])
    cube([arm_width, arm_thickness, mount_length + 20]);

  // Ghost MagSafe Insert (Red)
  %color("FireBrick", 0.8)
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length - magsafe_slot_depth/2])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 20], center=true);
}
