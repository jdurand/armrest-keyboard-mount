// Split Keyboard Armrest Mount - Slide-on insert with palm rest and mount cavity
// -------------------------------------------------

/* [Armrest Dimensions] */
arm_width_back = 96.0;
arm_width_front = 93.0;  // Set equal to arm_width_back if armrest has uniform width
arm_thickness = 24.8;
lip_width = 5.0;
fit_tolerance = 0.5;

/* [Ergonomics] */
tenting_angle = 20;
is_right_armrest = true; // TRUE = Right Armrest (Left High), FALSE = Left Armrest (Right High)

/* [Mount Configuration] */
wall_thickness = 4;
mount_length = 100;

// Thickness of the "Roof" (Material between top surface and MagSafe slot)
top_roof_thickness = 6.0;
// Thickness of the "Floor" (Material below MagSafe slot)
slot_floor_thickness = 4.0;

/* [Storage Options] */
enable_storage = true;
storage_lip_height = 1.0;

/* [Groove Settings] */
dish_depth = 4.5;
dish_radius = 75.0;
dish_offset_x = 45.0;   // Offset from center.
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

/* [Front Cover] */
render_cover = false;  // Set to true to render the front cover instead of main piece
cover_forward_depth = 10.0;  // How far the cover extends forward past the main piece
cover_taper_angle = 30.0;  // Forward taper angle for aesthetic finish

/* [Preview] */
preview_context = true;
$fn = 50;

// -------------------------------------------------
// GLOBAL GEOMETRY CALCULATIONS
// -------------------------------------------------

// --- FIXED HANDEDNESS LOGIC ---
// Standard Convention:
// Right Armrest: Tenting slopes UP to the Left (Left High, Right Low).
// Left Armrest: Tenting slopes UP to the Right (Right High, Left Low).

// 1. Rotation Fix:
// Right Armrest needs LEFT side HIGH. In standard XY coords, this is a NEGATIVE rotation (Clockwise).
// Left Armrest needs RIGHT side HIGH. This is a POSITIVE rotation (Counter-Clockwise).
rotation_val = is_right_armrest ? tenting_angle : -tenting_angle;

// Width calculations (support tapered armrest)
// Z=0 is back of mount (against chair), Z=mount_length is front (open end)
function arm_width_at_z(z) =
  let(ratio = min(1, max(0, z / mount_length)))
  arm_width_back + (arm_width_front - arm_width_back) * ratio;

function block_width_at_z(z) = arm_width_at_z(z) + 2*wall_thickness + fit_tolerance;

// Use back (widest) width for wedge height calculations
block_width = arm_width_back + 2*wall_thickness + fit_tolerance;

// Slot Geometry
slot_half_w = magsafe_slot_width / 2;
slot_half_t = magsafe_slot_thickness / 2;
slot_bbox_h = (magsafe_slot_width * abs(sin(rotation_val))) + (magsafe_slot_thickness * abs(cos(rotation_val)));

// Wedge Heights
rise = (block_width/2) * tan(abs(rotation_val));
h_taper_base = 3.0;
h_low_min = max(12.0, h_taper_base + 5);

h_center_safe = h_low_min + rise;
h_high_safe = h_center_safe + rise;

// 2. Height Assignments Fix:
// Right Armrest = Left High, Right Low.
// Left Armrest = Right High, Left Low.
h_left_safe  = is_right_armrest ? h_low_min : h_high_safe;
h_right_safe = is_right_armrest ? h_high_safe : h_low_min;

// Taper Geometry
h_left_taper = h_taper_base;
h_right_taper = h_taper_base;

// 3. Chamfer Fix:
// We want to chamfer the High Side (Inside) at the back.
// Right Armrest = Left High -> Chamfer Left.
chamfer_left = !is_right_armrest;
chamfer_right = is_right_armrest;

// 4. Groove/Taper Slope Fix:
// MOVED UP: Must be defined before used in groove_pitch calculation
taper_len = mount_length - magsafe_slot_depth;

// Groove slope needs to follow the Low Side (Outside) taper.
// Right Armrest -> Right Side is Low -> Use Right Taper
taper_rise = is_right_armrest ? (h_left_safe - h_left_taper) : (h_right_safe - h_right_taper);
groove_pitch = atan(taper_rise / taper_len);

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

// 5. Offset Fix:
// Groove is on the Low Side (Outside).
// Right Armrest -> Right Side is Low (+X) -> Offset Positive.
// Left Armrest -> Left Side is Low (-X) -> Offset Negative.
calc_offset_x = is_right_armrest ? -dish_offset_x : dish_offset_x;

y_surf_at_pos = get_surf_y_glob(dish_pos_z, calc_offset_x);
sphere_center_y = y_surf_at_pos + dish_radius + dish_depth;


// -------------------------------------------------
// MAIN ASSEMBLY
// -------------------------------------------------

difference() {
  // 1. POSITIVE BODY (Minkowski Rounded)
  minkowski() {
    union() {
      // A. Clamp Base Solid (hulled for tapered width)
      // Z=0 is back (wider), Z=mount_length is front (narrower)
      hull() {
        translate([0, 0, 0])
          linear_extrude(height = 0.1)
          clamp_outer_profile(rounding_r, arm_width_back);
        translate([0, 0, mount_length - 2*rounding_r])
          linear_extrude(height = 0.1)
          clamp_outer_profile(rounding_r, arm_width_front);
      }
      // B. Integrated Tapered Wedge
      translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
        constructive_wedge_solid(rounding_r);
    }
    sphere(r=rounding_r, $fn=40);
  }

  // 2. NEGATIVE CUTS

  // A. The Armrest Channel (hulled for tapered width)
  // Z=0 is back (wider), Z=mount_length is front (narrower)
  hull() {
    translate([0, 0, -5])
      linear_extrude(height = 0.1)
      clamp_armrest_channel_profile(arm_width_back);
    translate([0, 0, mount_length + 15])
      linear_extrude(height = 0.1)
      clamp_armrest_channel_profile(arm_width_front);
  }

  // A2. The Lip Gap (tapered with convex lip inner faces)
  // Circle subtractions create concave sides, leaving convex bulges on the lips
  translate([0, 0, -5])
    linear_extrude(height = mount_length + 20)
    clamp_lip_gap_profile(arm_width_back);

  // A2b. Taper the lip gap sides to match the wall taper
  gap_back = arm_width_back + fit_tolerance - 2*lip_width;
  gap_front = arm_width_front + fit_tolerance - 2*lip_width;
  gap_diff = (gap_back - gap_front) / 2;
  h_outer_cut = arm_thickness + (wall_thickness * 2) + fit_tolerance;
  if (gap_diff > 0) {
    // Cut triangular prisms on each side to taper the gap
    for (side = [-1, 1]) {
      hull() {
        translate([side * gap_back/2, -h_outer_cut/2 - 5, -5])
          cube([0.1, wall_thickness + 10, 0.1]);
        translate([side * gap_front/2, -h_outer_cut/2 - 5, mount_length + 15])
          cube([0.1, wall_thickness + 10, 0.1]);
      }
    }
  }

  // B. The MagSafe Slot (ALIGNED)
  // Using rotation_val (which is now correctly negative for Right Armrest)
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

  translate([0, arm_thickness + wall_thickness + h_taper_base + back_edge_round_r, 0])
    rotate([0, 90, 0])
    cylinder(r=back_edge_round_r, h=block_width*2, center=true);

  // E. The Comfort Groove
  translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
    translate([calc_offset_x, sphere_center_y, dish_pos_z])
      rotate([-groove_pitch, 0, 0])
      scale([1, 1, 4])
      sphere(r=dish_radius);

  // F. **OPTIONAL STORAGE COMPARTMENT**
  if (enable_storage) {
    translate([0, arm_thickness/2 + wall_thickness + fit_tolerance/2, 0])
      aligned_storage_cutout(slot_center_h_wedge);
  }
}

// -------------------------------------------------
// FRONT COVER (renders when render_cover = true)
// -------------------------------------------------

if (render_cover) {
  front_cover();
}

// -------------------------------------------------
// MODULES
// -------------------------------------------------

module front_cover() {
  // Simple front cover/cap that glues onto the front face of the wedge
  w_front = block_width_at_z(mount_length);
  cover_base_y = arm_thickness/2 + wall_thickness + fit_tolerance/2;

  // Taper inset - how much the front face shrinks on each edge
  front_taper_inset = cover_forward_depth * tan(cover_taper_angle);

  // Position at front of mount
  translate([0, 0, mount_length])
  difference() {
    // 1. POSITIVE: The cover body
    translate([0, cover_base_y, 0])
    hull() {
      // Back face - matches front of main piece exactly
      linear_extrude(0.1)
        wedge_chamfered_profile(w_front, h_left_safe, h_right_safe, rounding_r, taper_front_chamfer);

      // Front face - tapered inward from all sides
      translate([0, front_taper_inset, cover_forward_depth])
        linear_extrude(0.1)
        wedge_chamfered_profile(
          w_front - 2*front_taper_inset,     // Narrower (left & right taper)
          h_left_safe - front_taper_inset,   // Lower left
          h_right_safe - front_taper_inset,  // Lower right
          rounding_r,
          taper_front_chamfer - front_taper_inset  // Smaller chamfer
        );
    }

    // 2. NEGATIVE: MagSafe slot opening
    translate([0, cover_base_y + slot_center_h_wedge, cover_forward_depth/2])
      rotate([0, 0, rotation_val])
      cube([magsafe_slot_width, magsafe_slot_thickness, cover_forward_depth + 10], center=true);

    // 3. NEGATIVE: Storage compartment opening (if enabled)
    // Matches the triangular opening of the main piece's storage compartment
    if (enable_storage) {
      ceiling_y = slot_center_h_wedge - magsafe_slot_thickness/2 - slot_floor_thickness;
      difference() {
        // The full wedge void shape
        translate([0, cover_base_y, -1])
          linear_extrude(cover_forward_depth + 10)
          wedge_chamfered_void_profile(w_front, h_left_safe, h_right_safe, taper_front_chamfer);
        // Protect everything above the ceiling (same as main piece)
        translate([0, cover_base_y + ceiling_y, 0])
          rotate([0, 0, rotation_val])
          translate([0, 50, cover_forward_depth/2])
          cube([w_front*2, 100, cover_forward_depth + 20], center=true);
        // Protect the floor
        translate([0, cover_base_y, cover_forward_depth/2])
          cube([w_front*2, wall_thickness*2, cover_forward_depth + 20], center=true);
      }
    }
  }
}

module constructive_wedge_solid(r) {
  taper_len_local = mount_length - magsafe_slot_depth;
  w_back = block_width_at_z(0);
  w_taper_end = block_width_at_z(taper_len_local);
  w_front = block_width_at_z(mount_length);
  hull() {
    translate([0,0,0])
      linear_extrude(0.1)
      wedge_chamfered_profile(w_back, h_left_taper, h_right_taper, r, taper_back_chamfer);

    translate([0,0, taper_len_local - 2*r])
      linear_extrude(0.1)
      wedge_chamfered_profile(w_taper_end, h_left_safe, h_right_safe, r, taper_front_chamfer);
  }
  // Front section (MagSafe area) - hull to handle width change
  hull() {
    translate([0,0, taper_len_local - 2*r])
      linear_extrude(0.1)
      wedge_chamfered_profile(w_taper_end, h_left_safe, h_right_safe, r, taper_front_chamfer);
    translate([0,0, mount_length - 2*r])
      linear_extrude(0.1)
      wedge_chamfered_profile(w_front, h_left_safe, h_right_safe, r, taper_front_chamfer);
  }
}

module aligned_storage_cutout(slot_center_y) {
  storage_start_z = 10;
  ceiling_center_y = slot_center_y - magsafe_slot_thickness/2 - slot_floor_thickness;
  w_storage_start = block_width_at_z(storage_start_z);
  w_front = block_width_at_z(mount_length);
  w_max = max(w_storage_start, w_front);

  difference() {
    // 1. The Main Void Shape
    hull() {
      translate([0,0, storage_start_z])
        linear_extrude(0.1)
        wedge_chamfered_void_profile(w_storage_start, h_left_taper, h_right_taper, taper_back_chamfer);

      translate([0,0, mount_length])
        linear_extrude(0.1)
        wedge_chamfered_void_profile(w_front, h_left_safe, h_right_safe, taper_front_chamfer);
    }

    // 2. Ceiling Protection
    // Uses rotation_val to ensure the ceiling matches the magsafe slot angle
    translate([0, ceiling_center_y, 0])
       rotate([0, 0, rotation_val])
       translate([0, 50, 0])
       cube([w_max*2, 100, mount_length*3], center=true);

    // 3. Floor Protection
    translate([0, 0, 0]) cube([w_max*2, wall_thickness*2, mount_length*2], center=true);

    // 4. THE LIP
    translate([0, 0, mount_length - 2])
      cube([w_max*2, (wall_thickness + storage_lip_height)*2, 5], center=true);
  }
}

// BUG FIX: The right chamfer logic was previously missing the vertical offset (-chamfer_sz)
// causing a sharp corner that made the offset() fail when flipped.
module wedge_chamfered_void_profile(w, h_l, h_r, chamfer_sz) {
  offset(r = -wall_thickness)
  polygon(points=[
    [-w/2, 0],
    [w/2, 0],
    chamfer_right ? [w/2, h_r - chamfer_sz] : [w/2, h_r],
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

module clamp_outer_profile(r, width) {
  w_outer = width + (wall_thickness * 2) + fit_tolerance - 2*r;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance - 2*r;
  translate([-w_outer/2, -h_outer/2])
    square([w_outer, h_outer]);
}

// Armrest channel only (for tapered hull)
module clamp_armrest_channel_profile(width) {
  w_inner = width + fit_tolerance;
  h_inner = arm_thickness + fit_tolerance;
  translate([-w_inner/2, -h_inner/2])
    square([w_inner, h_inner]);
}

// Lip gap only (for tapered hull)
// Semicircle subtractions create convex bulges on lip inner faces
// Flat edge connects to wall, curved edge faces inward
module clamp_lip_gap_profile(width) {
  w_outer = width + (wall_thickness * 2) + fit_tolerance;
  h_outer = arm_thickness + (wall_thickness * 2) + fit_tolerance;
  w_inner = width + fit_tolerance;
  gap_width = w_inner - (2 * lip_width);
  cut_height = wall_thickness + 10;
  lip_bulge_r = wall_thickness / 2;  // Radius for convex lip ends
  gap_center_y = -h_outer/2 - 5 + cut_height/2;  // Vertical center of gap
  // Overlap amount to ensure solid connection (no gaps)
  overlap = 0.5;
  difference() {
    translate([-gap_width/2, -h_outer/2 - 5])
      square([gap_width, cut_height]);
    // Subtract semicircles from sides - flat edge at wall, curved edge inward
    // Right side: semicircle facing left (curved side toward center)
    translate([gap_width/2 + overlap, gap_center_y])
      intersection() {
        circle(r=lip_bulge_r, $fn=30);
        translate([-lip_bulge_r - overlap, -lip_bulge_r])
          square([lip_bulge_r + overlap, lip_bulge_r * 2]);
      }
    // Left side: semicircle facing right (curved side toward center)
    translate([-gap_width/2 - overlap, gap_center_y])
      intersection() {
        circle(r=lip_bulge_r, $fn=30);
        translate([0, -lip_bulge_r])
          square([lip_bulge_r + overlap, lip_bulge_r * 2]);
      }
  }
}

// -------------------------------------------------
// PREVIEW
// -------------------------------------------------
if (preview_context) {
  // Tapered armrest preview (Z=0 is back/wider, Z=mount_length is front/narrower)
  %color("Silver", 0.4)
  hull() {
    translate([-(arm_width_back)/2, -(arm_thickness)/2, -10])
      cube([arm_width_back, arm_thickness, 0.1]);
    translate([-(arm_width_front)/2, -(arm_thickness)/2, mount_length + 10])
      cube([arm_width_front, arm_thickness, 0.1]);
  }

  %color("FireBrick", 0.8)
  translate([0, slot_z_wedge, mount_length - magsafe_slot_depth/2])
    rotate([0, 0, rotation_val])
    cube([magsafe_slot_width, magsafe_slot_thickness, magsafe_slot_depth + 20], center=true);
}
