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
edge_radius = 1.0;      // 1mm Rounding
dish_depth = 2.0;       // Visible depth
dish_radius = 75.0;     // Gentle curve
dish_offset_x = 38.0;   // Moved to the LOWER (External) part of the wedge

/* [Ugreen MagSafe Cavity] */
magsafe_slot_width = 85.2;
magsafe_slot_thickness = 5;
magsafe_slot_depth = 75.0; // Starts 25mm from the back

/* [Preview] */
preview_context = true;
$fn = 60;

// -------------------------------------------------

// Calculate Geometry
rotation_val = is_right_armrest ? -tenting_angle : tenting_angle;
block_width = arm_width + 2*wall_thickness + fit_tolerance;

// Height Geometry
slot_half_w = magsafe_slot_width / 2;
slot_half_t = magsafe_slot_thickness / 2;
slot_bbox_h = (magsafe_slot_width * abs(sin(rotation_val))) + (magsafe_slot_thickness * abs(cos(rotation_val)));

// Center height relative to the wedge base (at X=0)
center_h = bottom_wall_slot + slot_bbox_h/2 + top_wall_min;

// Calculate Corner Heights
// rise is the vertical difference from center to edge
rise = (block_width/2) * tan(abs(rotation_val));
h_high = center_h + rise + 5;
h_low  = center_h - rise + 5;

// Assign based on side (Right Arm = Left High, Right Low)
h_left  = is_right_armrest ? h_high : h_low;
h_right = is_right_armrest ? h_low : h_high;

h_left_safe = max(h_left, 1);
h_right_safe = max(h_right, 1);

// --- FIX: ROBUST SURFACE HEIGHT CALCULATION ---
// We calculate the exact Y height of the surface at dish_offset_x
// Equation of line between (-w/2, h_left) and (w/2, h_right)
slope_m = (h_right_safe - h_left_safe) / block_width;
surface_y_at_dish = h_left_safe + slope_m * (dish_offset_x + block_width/2);

// Sphere center Y
sphere_y = surface_y_at_dish + dish_radius - dish_depth;

difference() {
  union() {
    // 1. The C-Clamp Base
    linear_extrude(height = mount_length)
      offset(r = edge_radius) offset(delta = -edge_radius)
      clamp_profile();

    // 2. The Angled Wedge
    translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
      difference() {
        // Main Block
        linear_extrude(height = mount_length)
          offset(r = edge_radius) offset(delta = -edge_radius)
          wedge_profile(rotation_val, block_width);

        // 3. The "Comfort Dish" (Fixed)
        // Positioned on the lower external side
        translate([dish_offset_x, sphere_y, 0])
          sphere(r=dish_radius);
      }
  }

  // 4. The Angled MagSafe Slot
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length - magsafe_slot_depth/2 + 0.1])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 1], center=true);

  // 5. Front Opening Cleanup
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length + 5])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, 20], center=true);
}

// -------------------------------------------------
// MODULES
// -------------------------------------------------

module clamp_profile() {
  w_outer = arm_width + (wall_thickness * 2) + fit_tolerance;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance;
  w_inner = arm_width + fit_tolerance;
  h_inner = arm_thickness + fit_tolerance;

  difference() {
    translate([-w_outer/2, -h_outer/2])
      square([w_outer, h_outer]);

    translate([-w_inner/2, -h_inner/2])
      square([w_inner, h_inner]);

    gap_width = w_inner - (2 * lip_width);
    cut_height = wall_thickness + 5;

    translate([-gap_width/2, -h_outer/2 - 1])
      square([gap_width, cut_height]);
  }
}

module wedge_profile(angle, w) {
  polygon(points=[
    [-w/2, 0],
    [w/2, 0],
    [w/2, h_right_safe],
    [-w/2, h_left_safe]
  ]);
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
