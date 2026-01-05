# Split Keyboard Armrest Mount

A 3D-printable slide-on mount for office chair armrests that holds split
keyboard halves using MagSafe-style magnetic mounts.

## Features

- **Slide-on design**: Clips securely onto standard office chair armrests
- **MagSafe cavity**: Holds UGREEN MagSafe-compatible mounts for quick keyboard
  attachment/detachment
- **Adjustable tenting**: Configurable tenting angle for ergonomic positioning
- **Optional storage**: Built-in storage compartment under the keyboard mount
- **Left/right variants**: Mirrored designs for each armrest

## Requirements

- [OpenSCAD](https://openscad.org/) for rendering STL files
  - `brew install openscad`
- 3D printer with ~100mm x 100mm build plate minimum
- [UGREEN MagSafe mount](https://amzn.to/4poFvvs) (or similar 85mm x 6mm magnetic mount)

## Default Dimensions

The default armrest dimensions are configured for the **Flexispot C7 Pro Max**
chair:

- Width: 96.0mm
- Thickness: 24.8mm

Use the `-w` and `-t` options to customize for your chair.

## Building

The `bin/build` script renders high-resolution STL files:

```bash
# Build both sides with storage (default)
./bin/build

# Build only right side
./bin/build -s right

# Build left side without storage
./bin/build -s left -n

# Build with custom tenting angle
./bin/build -a 15

# Build with custom armrest dimensions
./bin/build -w 90 -t 25

# Build right side, 20 degree tenting, no storage
./bin/build -s right -a 20 -n
```

Output STL files are saved to the `build/` directory. Import them into your
preferred slicer for printing.

### Options

| Option | Description |
|--------|-------------|
| `-s, --side SIDE` | Which side to build: `left`, `right`, or `both` (default: both) |
| `-S, --storage` | Enable storage compartment (default) |
| `-n, --no-storage` | Disable storage compartment |
| `-a, --angle DEGREES` | Tenting angle in degrees (default: 20) |
| `-w, --width MM` | Armrest width in mm (default: 96.0) |
| `-t, --thickness MM` | Armrest thickness in mm (default: 24.8) |
| `-r, --resolution N` | Set `$fn` resolution (default: 150) |
| `-h, --help` | Show help message |

## Customization

Open `src/armrest_mount.scad` in OpenSCAD and use the **Customizer** panel
(Window > Customizer) to adjust parameters without editing the source code.
Save your settings as a preset for easy recall.

Key parameters:

- `arm_width` / `arm_thickness`: Match your armrest dimensions
- `tenting_angle`: Default keyboard tilt angle
- `magsafe_slot_*`: Adjust for different magnetic mounts
- `dish_depth` / `dish_radius`: Palm rest comfort groove

## Contributing

Contributions are welcome! To submit changes:

1. Fork the repository
2. Create a branch for your changes
3. Open a pull request with:
   - A clear description of the changes
   - Screenshots showing the modified design in OpenSCAD
   - Any relevant measurements or test print results

## License

This work is licensed under [CC BY-NC-SA 4.0](LICENSE).

**Personal use**: Free to use, modify, and share.

**Commercial use**: Requires a separate license. Contact the author for
commercial licensing inquiries.
