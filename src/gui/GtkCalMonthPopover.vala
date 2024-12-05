[GtkTemplate (ui = "/ui/gcal-month-popover.ui")]
class GtkCal.MonthPopover : Gtk.Widget {
    [GtkChild]
    private unowned Gtk.Label day_label;
    [GtkChild]
    private unowned Gtk.ListBox listbox;
    [GtkChild]
    private unowned Gtk.Box main_box;
    [GtkChild]
    private unowned Gtk.Button new_event_button;

    private Adw.TimedAnimation animation;

    public GLib.ListStore events = new GLib.ListStore (typeof (GtkCal.Event));
    public void clear_events () {
        events = new GLib.ListStore (typeof (GtkCal.Event));
    }

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
            events = new GLib.ListStore (typeof (GtkCal.Event));
            update_event_list ();
        }
    }

    private bool _enable_new_event = false;
    public bool enable_new_event {
        get {
            return _enable_new_event;
        }
        set {
            _enable_new_event = value;
            new_event_button.visible = value;
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

    private int compare_events_cb (Object a, Object b) {
        /** TODO: multiday **/
        return GtkCal.Event.compare ((GtkCal.Event) a, (GtkCal.Event) b);
    }

    public void add_event (GtkCal.Event event) {
        debug ("adding event with uid %s to popup", event.uid);
        events.insert_sorted (event, compare_events_cb);
        update_event_list ();
    }

    public void popup () {
        visible = true;
        animation.reverse = false;
        animation.easing = Adw.Easing.EASE_OUT_EXPO;
        animation.play ();

        update_event_list ();
    }

    public void popdown () {
        animation.reverse = true;
        animation.easing = Adw.Easing.EASE_IN_EXPO;
        animation.play ();
    }

    /** Auxiliary functions **/
    private void update_event_list () {
        debug ("update_event_list");
        listbox.remove_all ();
        if (date == null) {
            return;
        }

        for ( int i = 0; i < events.get_n_items (); i++ ) {
            GtkCal.Event event = (GtkCal.Event) events.get_item (i);
            debug ("adding event with uid %s to listbox", event.uid);
            TimeZone tz;
            if (event.allday) {
                tz = new TimeZone.utc ();
            } else {
                tz = new TimeZone.local ();
            }

            DateTime event_start = new DateTime (tz,
                                                 event.date_start.get_year (),
                                                 event.date_start.get_month (),
                                                 event.date_start.
                                                 get_day_of_month (),
                                                 0, 0, 0);

            DateTime event_end = event_start.add_days (1);

            GtkCal.EventWidget event_widget = new GtkCal.EventWidget (event);
            event_widget.date_start = event_start;
            event_widget.date_end = event_end;

            Gtk.ListBoxRow row = new Gtk.ListBoxRow ();
            row.set_child (event_widget);
            row.activatable = false;


            listbox.append (row);

            event_widget.activate.connect (event_activated_cb);
        }
    }


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
        minimum_baseline = -1;
        natural_baseline = -1;
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
            debug ("allocating w %d h %d", width, height);
        }
    }

    /** Callbacks **/
    private void animation_cb (double value) {
        main_box.opacity = value;
        queue_allocate ();
    }

    private void on_animation_done_cb (Adw.Animation _animation) {
        if (_animation.value == 0) {
            visible = false;
        }
    }

    [GtkCallback]
    private void close_button_clicked_cb () {
        popdown ();
    }

    /** Signal handling **/
    public signal void event_activated (GtkCal.Event event);

    private void event_activated_cb (GtkCal.EventWidget event_widget) {
        event_activated (event_widget.event);
    }
}
