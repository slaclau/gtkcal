class GtkCal.OverflowBinLayout : Gtk.LayoutManager {
    public Gtk.SizeRequestMode request_mode { get; set; default = Gtk.
                                                                  SizeRequestMode
                                                                  .CONSTANT_SIZE
                                              ; }

    public override void measure (Gtk.Widget widget,
                                  Gtk.Orientation orientation,
                                  int for_size,
                                  out int minimum,
                                  out int natural,
                                  out int minimum_baseline,
                                  out int natural_baseline) {
        minimum = -1;
        natural = -1;
        minimum_baseline = -1;
        natural_baseline = -1;
        var request_mode = widget.get_request_mode ();
        for ( Gtk.Widget child = widget.get_first_child ();
              child != null;
              child = child.get_next_sibling ()) {
            int child_min_baseline = -1;
            int child_nat_baseline = -1;
            int child_min = 0;
            int child_nat = 0;

            if (!child.should_layout ()) {
                continue;
            }

            child.measure (orientation, for_size,
                           out child_min, out child_nat,
                           out child_min_baseline, out child_nat_baseline);

            minimum = int.max (minimum, child_min);
            natural = int.max (natural, child_nat);

            if (child_min_baseline > -1) {
                minimum_baseline = int.max (minimum_baseline, child_min_baseline
                                            );
            }
            if (child_nat_baseline > -1) {
                natural_baseline = int.max (natural_baseline, child_nat_baseline
                                            );
            }
        }

        switch (request_mode) {
        case Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH:
            if (orientation == Gtk.Orientation.VERTICAL) {
                minimum = 0;
                minimum_baseline = -1;
            }
            break;
        case Gtk.SizeRequestMode.WIDTH_FOR_HEIGHT:
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                minimum = 0;
                minimum_baseline = -1;
            }
            break;
        case Gtk.SizeRequestMode.CONSTANT_SIZE:
            minimum = 0;
            minimum_baseline = -1;
            break;
        }
    }

    public override void allocate (Gtk.Widget widget, int width, int height, int
                                   baseline) {
        for ( Gtk.Widget child = widget.get_first_child ();
              child != null;
              child = child.get_next_sibling ()) {
            Gtk.SizeRequestMode child_request_mode;
            int child_min_height = 0;
            int child_min_width = 0;

            if (!child.should_layout ()) {
                continue;
            }

            child_request_mode = child.get_request_mode ();

            switch (child_request_mode) {
            case Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH:
                child.measure (Gtk.Orientation.HORIZONTAL, -1, out
                               child_min_width, null, null, null);
                width = int.max (width, child_min_width);
                child.measure (Gtk.Orientation.HORIZONTAL, width, out
                               child_min_width, null, null, null);
                height = int.max (height, child_min_height);
                break;
            case Gtk.SizeRequestMode.WIDTH_FOR_HEIGHT:
                child.measure (Gtk.Orientation.HORIZONTAL, -1, out
                               child_min_width, null, null, null);
                height = int.max (height, child_min_height);
                child.measure (Gtk.Orientation.HORIZONTAL, height, out
                               child_min_width, null, null, null);
                width = int.max (width, child_min_width);
                break;
            case Gtk.SizeRequestMode.CONSTANT_SIZE:
                child.measure (Gtk.Orientation.HORIZONTAL, -1, out
                               child_min_width, null, null, null);
                width = int.max (width, child_min_width);
                child.measure (Gtk.Orientation.HORIZONTAL, -1, out
                               child_min_width, null, null, null);
                height = int.max (height, child_min_height);
                break;
            }

            child.allocate (width, height, baseline, null);
        }
    }
}
