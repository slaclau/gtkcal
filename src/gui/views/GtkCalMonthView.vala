[GtkTemplate (ui = "/ui/gcal-month-view.ui")]
public class GtkCal.MonthView : Gtk.Widget, Gtk.Buildable, GtkCal.View, GtkCal.
    TimelineSubscriber {
    public MonthView() {
        Object ();
    }
    static construct {
        set_css_name ("calendar-view");
    }
    private const int N_ROWS_PER_PAGE = 5;
    private const int N_PAGES = 5;
    private const int N_TOTAL_ROWS = N_ROWS_PER_PAGE * N_PAGES;

    private double row_offset = 0.0;

    [GtkChild]
    private unowned Gtk.Label label_0;
    [GtkChild]
    private unowned Gtk.Label label_1;
    [GtkChild]
    private unowned Gtk.Label label_2;
    [GtkChild]
    private unowned Gtk.Label label_3;
    [GtkChild]
    private unowned Gtk.Label label_4;
    [GtkChild]
    private unowned Gtk.Label label_5;
    [GtkChild]
    private unowned Gtk.Label label_6;

    [GtkChild]
    private unowned Gtk.Label month_label;
    [GtkChild]
    private unowned Gtk.Label year_label;

    [GtkChild]
    private unowned Gtk.EventController motion_controller;

    private Gtk.Widget header;

    private Gee.ArrayList<GtkCal.MonthViewRow> week_rows;

    private GtkCal.MonthPopover overflow_popover;
    private GtkCal.MonthViewRow overflow_row;
    private Gtk.Widget overflow_relative_to;


    private DateTime _date;
    public DateTime date {
        get {
            return _date;
        }
        set {
            bool week_changed = _date != null ||
                                value != null ||
                                _date.get_month () != value.get_month () ||
                                _date.get_week_of_year () != value.
                                get_week_of_year ();
            if (!week_changed) {
                return;
            }

            update_week_ranges (value);
            update_header_labels ();
            update_row_visuals ();
            range_changed ();
        }
    }

    public GtkCal.Range range {
        owned get {
            GtkCal.Range first_row_range = ((GtkCal.MonthViewRow) week_rows[0]).
                                           range;
            GtkCal.Range last_row_range = ((GtkCal.MonthViewRow) week_rows[
                                               week_rows.size - 1]).range;

            return GtkCal.Range.union (first_row_range, last_row_range);
        }
    }

    /** Construction **/

    construct {
        add_css_class ("view");
        this.update_weekday_labels ();
        week_rows = new Gee.ArrayList<GtkCal.MonthViewRow>();

        for ( int i = 0; i < N_TOTAL_ROWS; i++ ) {
            GtkCal.MonthViewRow row = new GtkCal.MonthViewRow ();
            row.event_activated.connect (on_event_activated_cb);
            row.show_overflow.connect (on_month_row_show_overflow_cb);
            row.set_parent (this);
            week_rows.add (row);
        }

        header.insert_before (this, null);

        overflow_popover = new GtkCal.MonthPopover ();
        overflow_popover.set_parent (this);

        DateTime now = new DateTime.now_local ();
        date = now;
    }

    private void update_weekday_labels () {
        int first_weekday = GtkCal.get_first_weekday ();

        label_0.set_text (GtkCal.get_weekday ((0 + first_weekday) % 7).up ());
        label_1.set_text (GtkCal.get_weekday ((1 + first_weekday) % 7).up ());
        label_2.set_text (GtkCal.get_weekday ((2 + first_weekday) % 7).up ());
        label_3.set_text (GtkCal.get_weekday ((3 + first_weekday) % 7).up ());
        label_4.set_text (GtkCal.get_weekday ((4 + first_weekday) % 7).up ());
        label_5.set_text (GtkCal.get_weekday ((5 + first_weekday) % 7).up ());
        label_6.set_text (GtkCal.get_weekday ((6 + first_weekday) % 7).up ());
    }

    private void update_header_labels () {
        int first_visible_row_index = N_ROWS_PER_PAGE * (N_PAGES - 1) / 2;
        GtkCal.MonthViewRow first_visible_row = (GtkCal.MonthViewRow) week_rows[
            first_visible_row_index];
        GtkCal.Range first_visible_row_range = first_visible_row.range;
        DateTime first_visible_date = first_visible_row_range.start;

        GtkCal.MonthViewRow last_visible_row = (GtkCal.MonthViewRow) week_rows[
            first_visible_row_index + N_ROWS_PER_PAGE - 1];
        GtkCal.Range last_visible_row_range = last_visible_row.range;
        DateTime last_visible_date_exclusive = last_visible_row_range.end;
        DateTime last_visible_date = last_visible_date_exclusive.add_seconds (-1
                                                                              );

        string month_string;
        string year_string;

        if (first_visible_date.get_month () == last_visible_date.get_month ()) {
            month_string = GtkCal.get_month_name (first_visible_date.get_month
                                                      () - 1);
        } else {
            month_string = "%s–%s".printf (
                GtkCal.get_month_name (first_visible_date.get_month () - 1),
                GtkCal.get_month_name (last_visible_date.get_month () - 1)
                );
        }

        if (first_visible_date.get_year () == last_visible_date.get_year ()) {
            year_string = "%d".printf (first_visible_date.get_year (          ))
            ;
        } else {
            year_string = "%d–%d".printf (
                first_visible_date.get_year (),
                last_visible_date.get_year ()
                );
        }
        month_label.set_text (month_string);
        year_label.set_text (year_string);
    }

    private void update_week_ranges (DateTime new_date) {
        GtkCal.Range current_range = null;
        int n_weeks_before = N_ROWS_PER_PAGE * (N_PAGES - 1) / 2;
        DateTime current_date = date;
        if (current_date != null) {
            current_date = date.add_days (0);
            current_range = range;
        }

        _date = new_date;

        if (current_range != null && current_range.contains_datetime (date)) {
            int diff = new_date.compare (current_date);
            GtkCal.MonthViewRow row = week_rows[n_weeks_before];
            GtkCal.Range row_range = row.range;

            while (!row_range.contains_datetime (new_date)) {
                if (diff > 0) {
                    move_top_row_to_bottom ();
                } else {
                    move_bottom_row_to_top ();
                }

                row = week_rows[n_weeks_before];
                row_range = row.range;
            }
        } else {
            for ( int i = 0; i < week_rows.size; i++ ) {
                DateTime row_date = date.add_weeks (i - n_weeks_before);
                DateTime week_start = GtkCal.date_time_get_start_of_week (
                    row_date);
                DateTime week_end = week_start.add_weeks (1);
                GtkCal.Range range = new GtkCal.Range (week_start, week_end,
                                                       GTKCAL_RANGE_DEFAULT);

                GtkCal.MonthViewRow row = (GtkCal.MonthViewRow) week_rows[i];
                row.range = range;
            }
        }

        dump_row_ranges ();
    }

    private void dump_row_ranges () {
#if ENABLE_TRACE
        for ( int i = 0; i < week_rows.size; i++ ) {
            GtkCal.MonthViewRow row = (GtkCal.MonthViewRow) week_rows[i];
            debug ("Row %u: %s", i, row.range.to_string (          ));
        }
#endif
    }

    private void update_row_visuals () {
        int first_visible_row_index = N_ROWS_PER_PAGE * (N_PAGES - 1) / 2;
        GtkCal.MonthViewRow first_visible_row = (GtkCal.MonthViewRow) week_rows[
            first_visible_row_index];
        GtkCal.Range first_visible_row_range = first_visible_row.range;

        GtkCal.MonthViewRow last_visible_row = (GtkCal.MonthViewRow) week_rows[
            first_visible_row_index + N_ROWS_PER_PAGE - 1];
        GtkCal.Range last_visible_row_range = last_visible_row.range;

        GtkCal.Range union_range = GtkCal.Range.union (first_visible_row_range,
                                                       last_visible_row_range);
        DateTime start = union_range.start;
        DateTime end = union_range.end;
        DateTime middle = start.add_days (GtkCal.date_time_compare_date (end,
                                                                         start)
                                          / 2);

        for ( int i = 0; i < week_rows.size; i++ ) {
            GtkCal.MonthViewRow row = (GtkCal.MonthViewRow) week_rows[i];
            row.update_style_for_date (middle);
        }
    }

    /** Destruct **/
    ~MonthView () {
        for ( int i = 0; i < week_rows.size; i++ ) {
            week_rows[i].unparent ();
        }
        header.unparent ();
        overflow_popover.unparent ();
    }

    /** Events **/

    private Gee.HashSet<GtkCal.Event> events = new Gee.HashSet<GtkCal.Event> ();
    public void add_event (GtkCal.Event event) {
        if (!events.add (event)) {
            warning ("event with uuid %s already added", event.uid);
        } else {
#if ENABLE_TRACE
            debug ("adding event with uuid %s", event.uid);
#endif
            for ( int i = 0; i < week_rows.size; i++ ) {
                var row = week_rows[i];
                var row_range = row.range;
                GtkCal.RangePosition position;

                var overlap = GtkCal.Range.calculate_overlap (row_range, event.
                                                              range, out
                                                              position);
#if ENABLE_TRACE
                debug ("event overlap with %s: %s - %s", row_range.to_string
                           (          ), overlap.to_string (          ),
                       position.to_string (          ));
#endif
                if (overlap != GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP) {
                    row.add_event (event);
                } else if (position == GtkCal.RangePosition.GTKCAL_RANGE_AFTER)
                {
                    break;
                }
            }
        }
    }

    /** Auxiliary methods **/
    private void allocate_overflow_popover (int height, int width, int baseline)
    {
        assert (overflow_relative_to != null);
        Graphene.Point origin, end;

        int header_height = header.get_height ();
        assert (overflow_relative_to.compute_point (this, Graphene.Point.zero ()
                                                    , out origin));
        assert (overflow_relative_to.compute_point (this, {
            overflow_relative_to.get_width (), overflow_relative_to.get_height
                ()
        }, out end));

        Gtk.Allocation cell_allocation = { (int) origin.x, (int) origin.y, (int)
                                           (end.x - origin.x), (int) (end.y -
                                                                      origin.y)
        };

        int popover_min_width;
        int popover_nat_width;
        int popover_height;
        int popover_width;

        overflow_popover.measure (Gtk.Orientation.HORIZONTAL, -1,
                                  out popover_min_width, out popover_nat_width,
                                  null, null);
        overflow_popover.measure (Gtk.Orientation.VERTICAL, -1,
                                  null, out popover_height, null, null);

        popover_width = popover_nat_width.clamp ((int) double.max (
                                                     popover_min_width,
                                                     cell_allocation
                                                     .width * 1.25),
                                                 (int) (cell_allocation.width *
                                                        1.5));
        popover_height = popover_height.clamp ((int) (cell_allocation.height *
                                                      1.5), height);

        Gtk.Allocation popover_allocation = { (int) double.max (0,
                                                                cell_allocation.
                                                                x - (
                                                                    popover_width
                                                                    -
                                                                    cell_allocation
                                                                    .width) /
                                                                2.0),
                                              (int) double.max (header_height,
                                                                cell_allocation.
                                                                y - (
                                                                    popover_height
                                                                    -
                                                                    cell_allocation
                                                                    .height) /
                                                                2.0),
                                              popover_width, popover_height };

        int popover_x2 = popover_allocation.x + popover_allocation.width;
        if (popover_x2 > width) {
            popover_allocation.x -= (popover_x2 - width);
        }
        int popover_y2 = popover_allocation.y + popover_allocation.height;
        if (popover_y2 > height) {
            popover_allocation.y -= (popover_y2 - height);
        }
        Gsk.Transform popover_transform = new Gsk.Transform ();
        popover_transform = popover_transform.translate ({ popover_allocation.x,
                                                           popover_allocation.y
                                                         });
        overflow_popover.allocate (popover_allocation.width, popover_allocation.
                                   height, baseline, popover_transform);
    }

    /** Signal handling **/
    private void on_event_activated_cb (GtkCal.Event event) {
        event_activated (event);
    }

    [GtkCallback]
    private void on_scroll_controller_scroll_begin_cb (Gtk.EventControllerScroll
                                                       scroll_controller){
        Gdk.Event event = scroll_controller.get_current_event ();
        if (event.get_event_type () != Gdk.EventType.TOUCHPAD_HOLD ||
            ((Gdk.TouchpadEvent) event).get_n_fingers () > 1) {
            add_css_class ("scrolling");
            cancel_row_offset_animation ();
            cancel_deceleration ();
        }
    }

    [GtkCallback]
    private bool on_scroll_controller_scroll_cb (Gtk.EventControllerScroll
                                                 scroll_controller,
                                                 double dx,
                                                 double dy) {
        Gdk.ScrollEvent event = (Gdk.ScrollEvent) scroll_controller.
                                get_current_event ();
        switch (event.get_direction ()) {
        case Gdk.ScrollDirection.SMOOTH:
            cancel_row_offset_animation ();
            cancel_deceleration ();
            offset_and_shuffle_rows_by_pixels (dy);
            return true;
        default:
            return false;
        }
    }

    [GtkCallback]
    private void on_scroll_controller_scroll_end_cb (Gtk.EventControllerScroll
                                                     scroll_controller){
        snap_to_top_row ();
    }

    [GtkCallback]
    private void on_scroll_controller_decelerate_cb (Gtk.EventControllerScroll
                                                     scroll_controller,
                                                     double velocity_x,
                                                     double velocity_y) {
        velocity_y /= 2.0;

        cancel_row_offset_animation ();
        cancel_deceleration ();

        int grid_height = get_grid_height ();

        if (Math.fabs (velocity_y) < (grid_height / (double) N_ROWS_PER_PAGE /
                                      5.0)) {
            snap_to_top_row ();
            return;
        }

        double duration = Math.fabs (velocity_y) / (double) get_height ();
        Adw.CallbackAnimationTarget animation_target = new Adw.
                                                       CallbackAnimationTarget (
            decelerate_scroll_cb);

        double row_height = grid_height / (double) N_ROWS_PER_PAGE;
        velocity_y -= Math.fmod (velocity_y, row_height) + row_offset *
                      row_height;

        assert (kinetic_scroll_animation == null);
        kinetic_scroll_animation = new Adw.TimedAnimation (this,
                                                           velocity_y,
                                                           0.0,
                                                           (int) (duration *
                                                                  1000),
                                                           animation_target);
        last_velocity = velocity_y;
        kinetic_scroll_animation.easing = Adw.Easing.EASE_OUT_EXPO;
        kinetic_scroll_animation.follow_enable_animations_setting = false;
        kinetic_scroll_animation.done.connect (on_kinetic_scroll_done_cb);
        kinetic_scroll_animation.play ();
    }

    [GtkCallback]
    private bool on_discrete_scroll_controller_scroll_cb (Gtk.
                                                          EventControllerScroll
                                                          scroll_controller,
                                                          double dx,
                                                          double dy) {
        Gdk.ScrollEvent current_event = (Gdk.ScrollEvent) scroll_controller.
                                        get_current_event ();
        int n_rows;
        switch (current_event.get_direction ()) {
        case Gdk.ScrollDirection.UP:
            n_rows = -1;
            break;
        case Gdk.ScrollDirection.DOWN:
            n_rows = 1;
            break;
        default:
            return false;
        }

        add_css_class ("scrolling");

        maybe_popdown_overflow_popover ();
        cancel_row_offset_animation ();
        cancel_deceleration ();

        animate_row_scroll (n_rows);

        return true;
    }



    private void decelerate_scroll_cb (double value) {
        double dy = last_velocity - value;
        last_velocity = value;

        if (Math.fabs (value) > (get_grid_height () / (double) N_ROWS_PER_PAGE /
                                 5.0)) {
            offset_and_shuffle_rows_by_pixels (dy);
        } else {
            kinetic_scroll_animation.skip ();
        }
    }

    private void on_kinetic_scroll_done_cb (Adw.Animation animation) {
        snap_to_top_row ();
    }

    private double last_velocity;

    /** Animation **/
    private Adw.TimedAnimation row_offset_animation;

    private void cancel_row_offset_animation () {
        if (row_offset_animation == null) {
            return;
        }
        row_offset_animation.pause ();
        row_offset_animation = null;
    }

    private Adw.TimedAnimation kinetic_scroll_animation;

    private void cancel_deceleration () {
        if (kinetic_scroll_animation == null) {
            return;
        }
        kinetic_scroll_animation.pause ();
        kinetic_scroll_animation = null;
    }

    private void animate_row_offset_cb (double value) {
        row_offset = value;
        queue_allocate ();
    }

    private void on_row_offset_animation_done (Adw.Animation animation) {
        remove_css_class ("scrolling");
        cancel_row_offset_animation ();

        row_offset = 0.0;
        queue_allocate ();
    }

    private void snap_to_top_row () {
        update_active_date ();
        dump_row_ranges ();

        Adw.CallbackAnimationTarget animation_target = new  Adw.
                                                       CallbackAnimationTarget (
            animate_row_offset_cb);
        row_offset_animation = new Adw.TimedAnimation (this, row_offset, 0.0,
                                                       200, animation_target);
        row_offset_animation.easing = Adw.Easing.EASE_OUT_QUAD;
        row_offset_animation.done.connect (on_row_offset_animation_done);
        row_offset_animation.play ();
    }

    private double? last_offset_location = null;

    private void animate_row_scroll_cb (double value) {
        assert (last_offset_location != null);

        double dy = value - last_offset_location;
        offset_and_shuffle_rows (dy);
        last_offset_location = value;
    }

    private void animate_row_scroll (int n_rows) {
        assert (n_rows != 0);

        update_active_date ();
        dump_row_ranges ();

        if (row_offset_animation == null) {
            bool animate = get_settings ().gtk_enable_animations;
            Adw.AnimationTarget animation_target = new Adw.
                                                   CallbackAnimationTarget (
                animate_row_scroll_cb);
            row_offset_animation = new Adw.TimedAnimation (this, row_offset,
                                                           n_rows, animate ? 150
            : 100, animation_target);
            row_offset_animation.easing = Adw.Easing.EASE_OUT_QUAD;
            row_offset_animation.follow_enable_animations_setting = false;
            row_offset_animation.done.connect (on_row_offset_animation_done);
            last_offset_location = row_offset;
            row_offset_animation.play ();
        }
    }

    private void update_active_date () {
        GtkCal.MonthViewRow top_row = week_rows[N_ROWS_PER_PAGE * (N_PAGES - 1)
                                                / 2];
        GtkCal.Range top_row_range = top_row.range;

        assert (top_row_range != null);
        date = top_row_range.start;
    }

    private void add_cached_events_to_row (GtkCal.MonthViewRow row) {
        GtkCal.Range row_range = row.range;

        foreach ( GtkCal.Event event in events ) {
            GtkCal.RangeOverlap overlap = GtkCal.Range.calculate_overlap (
                row_range, event.range, null);

            if (overlap == GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP) {
                continue;
            }

            row.add_event (event);
        }
    }

    private int get_grid_height () {
        return get_height () - header.get_height ();
    }

    private void offset_and_shuffle_rows (double dy) {
        row_offset += dy;
        if (Math.fabs (row_offset) > 0.5) {
            int rows_to_shuffle = (int) Math.round (Math.fabs (row_offset) + 0.5
                                                    );
            assert (rows_to_shuffle > 0);

            if (row_offset >= 0.0) {
                while (rows_to_shuffle-- > 0) {
                    move_top_row_to_bottom ();
                }
                row_offset = Math.fmod (row_offset, 0.5) - 0.5;
            } else {
                while (rows_to_shuffle-- > 0) {
                    move_bottom_row_to_top ();
                }
                row_offset = Math.fmod (row_offset, 0.5) + 0.5;
            }
            maybe_popdown_overflow_popover ();
            update_active_date ();
            dump_row_ranges ();
        }

        queue_allocate ();
    }

    private void offset_and_shuffle_rows_by_pixels (double dy) {
        int grid_height = get_grid_height ();
        double row_height = grid_height / (double) N_ROWS_PER_PAGE;
        offset_and_shuffle_rows (dy / row_height);
    }

    private void move_top_row_to_bottom () {
        GtkCal.Range last_row_range = week_rows[week_rows.size - 1].range;
        assert (last_row_range != null);

        DateTime last_row_range_end = last_row_range.end;
        assert (last_row_range_end != null);

        GtkCal.Range new_range = new GtkCal.Range (last_row_range_end,
                                                   last_row_range_end.add_weeks
                                                       (1), GtkCal.RangeType.
                                                   GTKCAL_RANGE_DEFAULT);

        debug ("Moved top row to bottom, new range: %s (last row range: %s)",
               new_range.to_string (), last_row_range.to_string ());

        GtkCal.MonthViewRow first_row = week_rows.remove_at (0);
        first_row.range = new_range;

        week_rows.insert (week_rows.size - 1, first_row);
        add_cached_events_to_row (first_row);
    }

    private void maybe_popdown_overflow_popover () {
        if (overflow_row == null) {
            return;
        }

        bool found = week_rows.contains (overflow_row);
        assert (found);

        uint row_index = week_rows.index_of (overflow_row);

        if (Math.floor (row_index / (double) N_ROWS_PER_PAGE) != Math.floor (
                N_PAGES / 2.0)) {
            overflow_popover.popdown ();
        }
    }

    private void move_bottom_row_to_top () {
        GtkCal.Range first_row_range = week_rows[0].range;
        assert (first_row_range != null);

        DateTime first_row_range_start = first_row_range.start;
        assert (first_row_range_start != null);

        GtkCal.Range new_range = new GtkCal.Range (first_row_range_start.
                                                   add_weeks (-1),
                                                   first_row_range_start, GtkCal
                                                   .RangeType.
                                                   GTKCAL_RANGE_DEFAULT);

        debug ("Moved bottom row to top, new range: %s (first row range: %s)",
               new_range.to_string (), first_row_range.to_string ());

        GtkCal.MonthViewRow last_row = week_rows.remove_at (week_rows.size - 1);
        last_row.range = new_range;

        week_rows.insert (0, last_row);
        add_cached_events_to_row (last_row);
    }

    /** Gtk.Buildable interface **/

    public void add_child (Gtk.Builder builder, Object child, string? type) {
        switch (type) {
        case "header":
            header = (Gtk.Widget) child;
            header.set_parent (this);
            break;
        default:
            base.add_child (builder, child, type);
            break;
        }
    }

    /** Gtk.Widget overrides **/

    public override void measure (Gtk.Orientation orientation,
                                  int for_size,
                                  out int minimum,
                                  out int natural,
                                  out int minimum_baseline,
                                  out int natural_baseline) {
        int minimum_header_size;
        int natural_header_size;
        int minimum_row_size = -1;
        int natural_row_size = -1;

        header.measure (orientation,
                        for_size,
                        out minimum_header_size,
                        out natural_header_size,
                        null, null);

        for ( int i = 0; i < week_rows.size; i++ ) {
            GtkCal.MonthViewRow row = (GtkCal.MonthViewRow) week_rows[i];
            int row_minimum;
            int row_natural;
            row.measure (orientation,
                         for_size,
                         out row_minimum,
                         out row_natural,
                         null, null);

            if (i == 0) {
                minimum_row_size = row_minimum;
                natural_row_size = row_natural;
            } else {
                minimum_row_size = int.min (minimum_row_size, row_minimum);
                natural_row_size = int.min (natural_row_size, row_natural);
            }
        }
        minimum = minimum_header_size + minimum_row_size;
        natural = natural_header_size + natural_row_size;
        minimum_baseline = -1;
        natural_baseline = -1;
    }

    public override void size_allocate (int width,
                                        int height,
                                        int baseline) {
        base.size_allocate (width, height, baseline);
        int header_height;
        header.measure (Gtk.Orientation.VERTICAL, width, out header_height, null
                        , null, null);
        header.allocate (width, header_height, baseline, null);

        int grid_height = height - header_height;
        double row_height = grid_height / (double) N_ROWS_PER_PAGE;
        double row_scroll_offset = row_offset * row_height;
        double y_offset = header_height - row_scroll_offset - (grid_height * ((
                                                                                  N_PAGES
                                                                                  -
                                                                                  1)
                                                                              /
                                                                              2.0));
        for ( int i = 0; i < week_rows.size; i++ ) {
            GtkCal.MonthViewRow row = (GtkCal.MonthViewRow) week_rows[i];

            Gtk.Allocation row_allocation = Gtk.Allocation ();

            row_allocation.x = 0;
            row_allocation.y = (int) Math.round (row_height * i + y_offset);
            row_allocation.width = width;
            row_allocation.height = (int) Math.round (row_height * (i + 1) +
                                                      y_offset) - row_allocation
                                    .y;
            var transform = new Gsk.Transform ();
            transform = transform.translate ({ row_allocation.x, row_allocation.
                                               y });
            row.allocate (row_allocation.width, row_allocation.height, baseline,
                          transform);
            if (overflow_popover.should_layout ()) {
                allocate_overflow_popover (height, width, baseline);
            }
        }
    }

    public override void snapshot (Gtk.Snapshot snapshot) {
        int width = get_width ();
        int height = get_height ();
        int header_height = header.get_height ();

        snapshot.push_clip ({ { 0, header_height }, { width, height -
                                                      header_height } });

        for ( int i = 0; i < week_rows.size; i++ ) {
            var row = (GtkCal.MonthViewRow) week_rows[i];
            snapshot_child ((GtkCal.MonthViewRow) week_rows[i], snapshot);
        }
        snapshot.pop ();

        snapshot_child (header, snapshot);

        snapshot_child (overflow_popover, snapshot);
    }

    /** Callbacks **/
    public void on_month_row_show_overflow_cb (GtkCal.MonthViewRow row, GtkCal.
                                               MonthCell cell) {
        debug ("overflow activated for row: %s, cell: %s", row.range.to_string
                   (), cell.date.format_iso8601 ());
        overflow_row = row;
        overflow_relative_to = cell;

        overflow_popover.date = cell.date;

        DateTime start_dt = new DateTime.local (overflow_popover.date.get_year
                                                    (),
                                                overflow_popover.date.get_month
                                                    (),
                                                overflow_popover.date.
                                                get_day_of_month (),
                                                0, 0, 0);
        DateTime end_dt = start_dt.add_days (1);
        GtkCal.Range cell_range = new GtkCal.Range (start_dt, end_dt, GtkCal.
                                                    RangeType.
                                                    GTKCAL_RANGE_DEFAULT);
        overflow_popover.clear_events ();
        foreach ( GtkCal.Event event in events ) {
            GtkCal.RangeOverlap overlap = GtkCal.Range.calculate_overlap (
                cell_range, event.range, null);

            if (overlap == GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP) {
                continue;
            }
            overflow_popover.add_event (event);
        }
        overflow_popover.popup ();
        // TODO: motion_controller.propagation_phase = Gtk.PropagationPhase.NONE;
        // TODO: clear_marks();
    }
}
