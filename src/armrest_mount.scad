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
taper_back_chamfer = 25.0; // Large taper at the back (Comfort)
taper_front_chamfer = 5.0; // Small taper at the front (Slot safety)

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
// We calculate the full trapezoid heights first
rise = (block_width/2) * tan(abs(rotation_val));
h_high = center_h + rise + 5;
h_low  = center_h - rise + 5;
h_left_safe  = is_right_armrest ? h_high : h_low;
h_right_safe = is_right_armrest ? h_low : h_high;

// Taper Geometry (Back Section)
// Low profile at the back
h_taper_base = 6;
h_left_taper = h_taper_base;
h_right_taper = h_taper_base;

// Taper/Chamfer Direction
// Right Arm -> Left is High/Inside -> Chamfer Left Corner
chamfer_left = is_right_armrest;
chamfer_right = !is_right_armrest;

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
      // Uses hull() to smoothly transition profiles. No cuts.
      translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
        constructive_wedge_solid(block_width, rounding_r);
    }
    // The Rounding Tool
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
  // Rounds the entry point for the arm
  translate([0, arm_thickness*2, 0])
    rotate([0, 90, 0])
    translate([0, 0, -block_width])
      cylinder(r=back_edge_round_r, h=block_width*2);

  // E. Top-Back Smooth Roundover
  // Rounds the top edge of the taper
  translate([0, arm_thickness + wall_thickness*2 + h_taper_base + back_edge_round_r, 0])
    rotate([0, 90, 0])
    cylinder(r=back_edge_round_r, h=block_width*2, center=true);
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
  // Continuous extrusion of the "Slot Start" profile
  translate([0,0, taper_len - 2*r])
    linear_extrude(height = magsafe_slot_depth)
    wedge_chamfered_profile(w, h_left_safe, h_right_safe, r, taper_front_chamfer);
}

// Custom Profile that clips the "Inside" corner
module wedge_chamfered_profile(w, h_l, h_r, r, chamfer_sz) {
  offset(r = -r)
  polygon(points=[
    // Bottom Base (Extended -5mm for fusion)
    [-w/2, -5],
    [w/2, -5],

    // Right Side
    // If chamfer_right is true, we clip the Top-Right corner
    chamfer_right ? [w/2, h_r - chamfer_sz] : [w/2, h_r],
    chamfer_right ? [w/2 - chamfer_sz, h_r] : [w/2, h_r], // Duplicate if no chamfer (harmless)

    // Left Side
    // If chamfer_left is true, we clip the Top-Left corner
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
