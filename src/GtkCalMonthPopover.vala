[GtkTemplate (ui = "/ui/gcal-month-popover.ui")]
class GtkCal.MonthPopover : Gtk.Widget {
    [GtkChild]
    private unowned Gtk.Label day_label;
    [GtkChild]
    private unowned Gtk.ListBox listbox;
    [GtkChild]
    private unowned Gtk.Box main_box;

    private Adw.TimedAnimation animation;

    private DateTime _date;
    public DateTime date {
        get {
            return _date;
        }
        set {
            if (_date != null && value != null && GtkCal.date_time_compare_date
                    (_date, value) == 0) {
                return;
            }

            if (value != null) {
                _date = value;
                day_label.label = "%d".printf (date.get_day_of_month ());
            }
        }
    }

    static construct {
        set_css_name ("monthpopover");
    }

    construct {
        animation = new Adw.TimedAnimation (this, 0.0, 1.0, 250, new Adw.
                                            CallbackAnimationTarget (
                                                animation_cb));
        animation.done.connect (on_animation_done_cb);
    }

    public void popup () {
        visible = true;
        animation.reverse = false;
        animation.easing = Adw.Easing.EASE_OUT_EXPO;
        animation.play ();

        // TODO: implement update_event_list();
    }

    /** Auxiliary functions **/
    private static float lerp (double from, double to, double progress) {
        return (float) (from * (1.0 - progress) + to * progress);
    }

    private Gsk.Transform create_transform (int height, int width) {
        Gsk.Transform transform = new Gsk.Transform ();

        Graphene.Point offset;
        offset = { width / 2.0f, height / 2.0f };
        transform = transform.translate (offset);

        double progress = animation.value;
        float scale = lerp (0.75, 1.0, progress);
        transform = transform.scale (scale, scale);

        offset = { -width / 2.0f, -height / 2.0f };
        transform = transform.translate (offset);

        return transform;
    }

    /** Gtk.Widget overrides **/
    public override void measure (Gtk.Orientation orientation,
                                  int for_size,
                                  out int minimum,
                                  out int natural,
                                  out int minimum_baseline,
                                  out int natural_baseline) {
        for ( Gtk.Widget child = get_first_child (); child != null; child =
                  child.get_next_sibling ()) {
            int child_min_baseline = -1;
            int child_nat_baseline = -1;
            int child_min = 0;
            int child_nat = 0;

            if (!child.should_layout ()) {
                continue;
            }

            child.measure (orientation, for_size, out child_min, out child_nat,
                           out child_min_baseline, out child_nat_baseline);

            minimum = int.max (minimum, child_min);
            natural = int.max (natural, child_nat);

            if (child_min_baseline >= -1) {
                minimum_baseline = int.max (minimum_baseline, child_min_baseline
                                            );
            }
            if (child_nat_baseline >= -1) {
                natural_baseline = int.max (natural_baseline, child_nat_baseline
                                            );
            }
        }
    }

    public override void size_allocate (int width, int height, int baseline) {
        Gsk.Transform transform = create_transform (width, height);

        for ( Gtk.Widget child = get_first_child (); child != null; child =
                  child.get_next_sibling ()) {
            if (!child.should_layout ()) {
                continue;
            }
            child.allocate (width, height, baseline, transform);
        }
    }

    /** Callbacks **/
    private void animation_cb (double value) {
        main_box.opacity = value;
        queue_allocate ();
    }

    private void on_animation_done_cb (Adw.Animation animation) {
        if (animation.value == 0) {
            visible = false;
        }
    }
}
