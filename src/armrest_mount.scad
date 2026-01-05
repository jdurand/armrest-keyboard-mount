// Split Keyboard Armrest Mount - Slide-on insert with palm rest and mount cavity
// -------------------------------------------------

/* [Armrest Dimensions] */
arm_width = 96.0;
arm_thickness = 24.8;
lip_width = 5.0;       // Grip under the armrest
fit_tolerance = 0.5;   // Extra gap for sliding fit

/* [Ergonomics] */
tenting_angle = 15;      // 15 degrees tilt (Left/Right)
is_right_armrest = true; // TRUE = Right Arm

/* [Mount Configuration] */
wall_thickness = 4;     // Solid walls
mount_length = 100;     // Total length
top_wall_min = 6.0;     // Roof thickness
bottom_wall_slot = 4.0; // Floor thickness below slot

/* [Comfort & Aesthetics] */
rounding_r = 1.5;       // 1.5mm global rounding radius
back_edge_round_r = 5.0; // Roundover for the very back edge
taper_back_chamfer = 35.0; // Aggressive taper at the back (35mm)
taper_front_chamfer = 12.0; // Increased taper at the front (12mm)

/* [Dish Settings] */
dish_depth = 2.0;       // Depth of the scoop
dish_radius = 75.0;     // Radius of the scoop
dish_offset_x = 38.0;   // Position (Right side)
dish_pos_z = 15.0;      // Position along the length (from back)

/* [Ugreen MagSafe Cavity] */
magsafe_slot_width = 85.2;
magsafe_slot_thickness = 5.0;
magsafe_slot_depth = 75.0;

/* [Preview] */
preview_context = true;
$fn = 60;

// -------------------------------------------------

// Calculate Geometry
rotation_val = is_right_armrest ? -tenting_angle : tenting_angle;
block_width = arm_width + 2*wall_thickness + fit_tolerance;

// Slot Geometry
slot_half_w = magsafe_slot_width / 2;
slot_half_t = magsafe_slot_thickness / 2;
slot_bbox_h = (magsafe_slot_width * abs(sin(rotation_val))) + (magsafe_slot_thickness * abs(cos(rotation_val)));
center_h = bottom_wall_slot + slot_bbox_h/2 + top_wall_min;

// Wedge Heights (Front/Slot Section)
rise = (block_width/2) * tan(abs(rotation_val));
h_high = center_h + rise + 5;
h_low  = center_h - rise + 5;
h_left_safe  = is_right_armrest ? h_high : h_low;
h_right_safe = is_right_armrest ? h_low : h_high;

// Taper Geometry (Back Section)
h_taper_base = 5;
h_left_taper = h_taper_base;
h_right_taper = h_taper_base;

// Chamfer Directions
chamfer_left = is_right_armrest;
chamfer_right = !is_right_armrest;

// --- DISH HEIGHT CALCULATION ---
// We need to find the exact Y height of the surface at the dish position (X, Z)
// to ensure the sphere cuts exactly 'dish_depth' deep.

// 1. Interpolate profiles at dish_pos_z
taper_len = mount_length - magsafe_slot_depth; // 25mm
ratio = min(1, max(0, dish_pos_z / taper_len));

h_l_at_z = h_left_taper + (h_left_safe - h_left_taper) * ratio;
h_r_at_z = h_right_taper + (h_right_safe - h_right_taper) * ratio;
chamfer_at_z = taper_back_chamfer + (taper_front_chamfer - taper_back_chamfer) * ratio;

// 2. Define the top surface line at Z
// Left Point: x = -w/2 + chamfer (if chamfer left), y = h_l
// Right Point: x = w/2 (if no chamfer right), y = h_r
// Note: We assume Right Armrest -> Chamfer Left, Right is full.
x_left_node = -block_width/2 + (chamfer_left ? chamfer_at_z : 0);
y_left_node = h_l_at_z;
x_right_node = block_width/2 - (chamfer_right ? chamfer_at_z : 0);
y_right_node = h_r_at_z;

// 3. Calculate Surface Y at dish_offset_x
run = x_right_node - x_left_node;
slope = (y_right_node - y_left_node) / run;
dist_from_left = dish_offset_x - x_left_node;
surface_y_at_dish = y_left_node + slope * dist_from_left;

// 4. Sphere Center Y
sphere_center_y = surface_y_at_dish + dish_radius - dish_depth;


// -------------------------------------------------
// MAIN ASSEMBLY
// -------------------------------------------------

difference() {
  // 1. POSITIVE BODY (Minkowski Rounded)
  minkowski() {
    union() {
      // A. Clamp Base Solid
      linear_extrude(height = mount_length - 2*rounding_r)
        translate([0,0])
        clamp_outer_profile(rounding_r);

      // B. Integrated Tapered Wedge
      translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
        constructive_wedge_solid(block_width, rounding_r);
    }
    sphere(r=rounding_r, $fn=12);
  }

  // 2. NEGATIVE CUTS

  // A. The Armrest Channel
  translate([0, 0, -5])
    linear_extrude(height = mount_length + 20)
      clamp_inner_cut_profile();

  // B. The MagSafe Slot
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length - magsafe_slot_depth/2 + 0.1])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 1], center=true);

  // C. Front Opening Cleanup
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length + 5])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, 20], center=true);

  // D. "Waterfall" Back Edge Roundover (Z=0)
  translate([0, arm_thickness*2, 0])
    rotate([0, 90, 0])
    translate([0, 0, -block_width])
      cylinder(r=back_edge_round_r, h=block_width*2);

  // E. Top-Back Smooth Roundover
  translate([0, arm_thickness + wall_thickness*2 + h_taper_base + back_edge_round_r, 0])
    rotate([0, 90, 0])
    cylinder(r=back_edge_round_r, h=block_width*2, center=true);

  // F. The Comfort Dish (Restored)
  // Positioned relative to the wedge top surface
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0]) // Shift to wedge frame
    translate([dish_offset_x, sphere_center_y, dish_pos_z])
      sphere(r=dish_radius);
}


// -------------------------------------------------
// MODULES
// -------------------------------------------------

module constructive_wedge_solid(w, r) {
  taper_len = mount_length - magsafe_slot_depth; // e.g. 25mm

  // Section 1: The Transition (Back -> Slot Start)
  hull() {
    // Z=0: Back Profile (Low + Large Chamfer)
    translate([0,0,0])
      linear_extrude(0.1)
      wedge_chamfered_profile(w, h_left_taper, h_right_taper, r, taper_back_chamfer);

    // Z=25: Slot Start Profile (High + Small Chamfer)
    translate([0,0, taper_len - 2*r])
      linear_extrude(0.1)
      wedge_chamfered_profile(w, h_left_safe, h_right_safe, r, taper_front_chamfer);
  }

  // Section 2: The Main Slot Body (Slot Start -> Front)
  translate([0,0, taper_len - 2*r])
    linear_extrude(height = magsafe_slot_depth)
    wedge_chamfered_profile(w, h_left_safe, h_right_safe, r, taper_front_chamfer);
}

// Custom Profile that clips the "Inside" corner
module wedge_chamfered_profile(w, h_l, h_r, r, chamfer_sz) {
  offset(r = -r)
  polygon(points=[
    [-w/2, -5],
    [w/2, -5],

    // Right Side
    chamfer_right ? [w/2, h_r - chamfer_sz] : [w/2, h_r],
    chamfer_right ? [w/2 - chamfer_sz, h_r] : [w/2, h_r],

    // Left Side
    chamfer_left ? [-w/2 + chamfer_sz, h_l] : [-w/2, h_l],
    chamfer_left ? [-w/2, h_l - chamfer_sz] : [-w/2, h_l]
  ]);
}

module clamp_outer_profile(r) {
  w_outer = arm_width + (wall_thickness * 2) + fit_tolerance - 2*r;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance - 2*r;
  translate([-w_outer/2, -h_outer/2])
    square([w_outer, h_outer]);
}

module clamp_inner_cut_profile() {
  w_outer = arm_width + (wall_thickness * 2) + fit_tolerance;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance;
  w_inner = arm_width + fit_tolerance;
  h_inner = arm_thickness + fit_tolerance;

  translate([-w_inner/2, -h_inner/2])
    square([w_inner, h_inner]);

  gap_width = w_inner - (2 * lip_width);
  cut_height = wall_thickness + 10;

  translate([-gap_width/2, -h_outer/2 - 5])
    square([gap_width, cut_height]);
}

// -------------------------------------------------
// PREVIEW
// -------------------------------------------------
if (preview_context) {
  %color("Silver", 0.4)
  translate([-(arm_width)/2, -(arm_thickness)/2, -10])
    cube([arm_width, arm_thickness, mount_length + 20]);

  %color("FireBrick", 0.8)
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2 + bottom_wall_slot + (slot_bbox_h/2), mount_length - magsafe_slot_depth/2])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 20], center=true);
}
