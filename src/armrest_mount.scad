// Split Keyboard Armrest Mount - Slide-on insert with palm rest and mount cavity
// -------------------------------------------------

/* [Armrest Dimensions] */
arm_width = 96.0;
arm_thickness = 24.8;
lip_width = 5.0;
fit_tolerance = 0.5;

/* [Ergonomics] */
tenting_angle = 20;
is_right_armrest = true;

/* [Mount Configuration] */
wall_thickness = 4;     // Main wall thickness
mount_length = 100;

// Thickness of the "Roof" (Material between top surface and MagSafe slot)
top_roof_thickness = 6.0;

// Thickness of the "Floor" (Material below MagSafe slot)
slot_floor_thickness = 4.0;

/* [Storage Options] */
enable_storage = true; // Set to false to close the front compartment
storage_lip_height = 1.0; // Height of the small lip at the front

/* [Groove Settings] */
dish_depth = 2.5;       // Depth of cut into top surface
dish_radius = 75.0;
dish_offset_x = 46.0;
dish_pos_z = 15.0;

/* [Ugreen MagSafe Cavity] */
magsafe_slot_width = 85.2;
magsafe_slot_thickness = 6.0;
magsafe_slot_depth = 75.0;

/* [Comfort & Aesthetics] */
rounding_r = 1.5;
back_edge_round_r = 5.0;
taper_back_chamfer = 35.0;
taper_front_chamfer = 12.0;

/* [Preview] */
preview_context = true;
$fn = 40;

// -------------------------------------------------
// GLOBAL GEOMETRY CALCULATIONS
// -------------------------------------------------

rotation_val = is_right_armrest ? -tenting_angle : tenting_angle;
block_width = arm_width + 2*wall_thickness + fit_tolerance;

// Slot Geometry
slot_half_w = magsafe_slot_width / 2;
slot_half_t = magsafe_slot_thickness / 2;
slot_bbox_h = (magsafe_slot_width * abs(sin(rotation_val))) + (magsafe_slot_thickness * abs(cos(rotation_val)));

// Wedge Heights
rise = (block_width/2) * tan(abs(rotation_val));
h_taper_base = 5.0;
h_low_min = max(12.0, h_taper_base + 5);

h_center_safe = h_low_min + rise;
h_high_safe = h_center_safe + rise;

h_left_safe  = is_right_armrest ? h_high_safe : h_low_min;
h_right_safe = is_right_armrest ? h_low_min : h_high_safe;

// Taper Geometry
h_left_taper = h_taper_base;
h_right_taper = h_taper_base;

// Chamfers
chamfer_left = is_right_armrest;
chamfer_right = !is_right_armrest;

// Groove Geometry
taper_len = mount_length - magsafe_slot_depth;
taper_rise_right = h_right_safe - h_right_taper;
groove_pitch = atan(taper_rise_right / taper_len);

// MagSafe Position Logic (Global)
slot_center_h_wedge = h_center_safe - top_roof_thickness - magsafe_slot_thickness/2;
slot_z_wedge = arm_thickness/2 + wall_thickness + fit_tolerance/2 + slot_center_h_wedge;

// Surface Height Logic for Groove (Global Function)
function get_surf_y_glob(z, x) =
  let(
    rat = min(1, max(0, z/taper_len)),
    hl = h_left_taper + (h_left_safe - h_left_taper) * rat,
    hr = h_right_taper + (h_right_safe - h_right_taper) * rat,
    cf = taper_back_chamfer + (taper_front_chamfer - taper_back_chamfer) * rat,
    xl = -block_width/2 + (chamfer_left ? cf : 0),
    xr = block_width/2 - (chamfer_right ? cf : 0),
    m = (hr - hl)/(xr - xl)
  )
  hl + m * (x - xl);

// Calculate Sphere Center Global
y_surf_at_pos = get_surf_y_glob(dish_pos_z, dish_offset_x);
// Reverted as requested: No absolute value
sphere_center_y = y_surf_at_pos + dish_radius + dish_depth;


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

  // B. The MagSafe Slot (ALIGNED)
  translate([0, slot_z_wedge, mount_length - magsafe_slot_depth/2 + 0.1])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 1], center=true);

  // C. Front Opening Cleanup
  translate([0, slot_z_wedge, mount_length + 5])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, 20], center=true);

  // D. Back Edge Roundovers
  translate([0, arm_thickness*2, 0])
    rotate([0, 90, 0])
    translate([0, 0, -block_width])
      cylinder(r=back_edge_round_r, h=block_width*2);

  translate([0, arm_thickness + wall_thickness*2 + h_taper_base + back_edge_round_r, 0])
    rotate([0, 90, 0])
    cylinder(r=back_edge_round_r, h=block_width*2, center=true);

  // E. The Comfort Groove
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
    translate([dish_offset_x, sphere_center_y, dish_pos_z])
      rotate([-groove_pitch, 0, 0])
      scale([1, 1, 4])
      sphere(r=dish_radius);

  // F. **OPTIONAL STORAGE COMPARTMENT**
  if (enable_storage) {
    translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
      aligned_storage_cutout(block_width, slot_center_h_wedge);
  }
}


// -------------------------------------------------
// MODULES
// -------------------------------------------------

module constructive_wedge_solid(w, r) {
  taper_len_local = mount_length - magsafe_slot_depth;
  hull() {
    translate([0,0,0])
      linear_extrude(0.1)
      wedge_chamfered_profile(w, h_left_taper, h_right_taper, r, taper_back_chamfer);

    translate([0,0, taper_len_local - 2*r])
      linear_extrude(0.1)
      wedge_chamfered_profile(w, h_left_safe, h_right_safe, r, taper_front_chamfer);
  }
  translate([0,0, taper_len_local - 2*r])
    linear_extrude(height = magsafe_slot_depth)
    wedge_chamfered_profile(w, h_left_safe, h_right_safe, r, taper_front_chamfer);
}

module aligned_storage_cutout(w, slot_center_y) {
  storage_start_z = 10;
  // Ceiling is Slot Floor - Floor Thickness
  ceiling_center_y = slot_center_y - magsafe_slot_thickness/2 - slot_floor_thickness;

  // LIP LOGIC:
  // To create a lip, we stop the void slightly before the front face.
  // The "front face" is at mount_length.
  // We want the void to be cut all the way, BUT we want to add a small wall at the bottom front.
  // Or simpler: We just don't cut the bottom 1mm at the front.

  // Since we are subtracting this shape, if we want a lip, we REMOVE that part of the subtraction shape.
  // We can subtract a "Lip Block" from the "Void Shape" before using it to cut the main body.

  difference() {
    // 1. The Main Void Shape
    hull() {
      translate([0,0, storage_start_z])
        linear_extrude(0.1)
        wedge_chamfered_void_profile(w, h_left_taper, h_right_taper, taper_back_chamfer);

      translate([0,0, mount_length])
        linear_extrude(0.1)
        wedge_chamfered_void_profile(w, h_left_safe, h_right_safe, taper_front_chamfer);
    }

    // 2. Ceiling Protection
    translate([0, ceiling_center_y, 0])
       rotate([0, 0, rotation_val])
       translate([0, 50, 0])
       cube([w*2, 100, mount_length*3], center=true);

    // 3. Floor Protection
    translate([0, 0, 0]) cube([w*2, wall_thickness*2, mount_length*2], center=true);

    // 4. THE LIP (New)
    // We protect a small block at the bottom front of the void.
    // This effectively "uncuts" the void at that spot, leaving plastic.
    translate([0, 0, mount_length - 2]) // At the very front
      cube([w*2, (wall_thickness + storage_lip_height)*2, 5], center=true);
      // Center is Y=0. Height covers 2*(wall + lip).
      // Since void starts at Y=wall, this covers up to Y=wall+lip. Correct.
  }
}

module wedge_chamfered_void_profile(w, h_l, h_r, chamfer_sz) {
  offset(r = -wall_thickness)
  polygon(points=[
    [-w/2, 0],
    [w/2, 0],
    chamfer_right ? [w/2, h_r] : [w/2, h_r],
    chamfer_right ? [w/2 - chamfer_sz, h_r] : [w/2, h_r],
    chamfer_left ? [-w/2 + chamfer_sz, h_l] : [-w/2, h_l],
    chamfer_left ? [-w/2, h_l - chamfer_sz] : [-w/2, h_l]
  ]);
}

module wedge_chamfered_profile(w, h_l, h_r, r, chamfer_sz) {
  offset(r = -r)
  polygon(points=[
    [-w/2, -5],
    [w/2, -5],
    chamfer_right ? [w/2, h_r - chamfer_sz] : [w/2, h_r],
    chamfer_right ? [w/2 - chamfer_sz, h_r] : [w/2, h_r],
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
  translate([0, slot_z_wedge, mount_length - magsafe_slot_depth/2])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 20], center=true);
}
