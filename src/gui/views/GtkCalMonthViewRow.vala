private class GtkCal.EventBlock {
    public Gtk.Widget event_widget;
    public int length;
    public int cell;
    /* These are updated during allocation */
    public bool visible;
    public int height;
}

public class GtkCal.MonthViewRow : Gtk.Widget {
    private GLib.ListStore events = new GLib.ListStore (typeof (GtkCal.Event));
    private Gee.HashMap<GtkCal.Event, Gee.ArrayList<GtkCal.EventBlock?> >
    layout_blocks;

    public GLib.ListStore get_events () {
        return events;
    }

    private GtkCal.MonthCell[] day_cells;

    private GtkCal.Range _range;
    public GtkCal.Range range {
        get {
            return _range;
        }
        set {
            _range = value;

            remove_event_widgets ();
            events.remove_all ();
            layout_blocks.clear ();

            DateTime start = range.start;
            for ( int i = 0; i < 7; i++ ) {
                DateTime day = start.add_days (i);
                day_cells[i].date = day;
            }
        }
    }

    construct {
        layout_blocks = new Gee.HashMap<GtkCal.Event, Gee.ArrayList<GtkCal.
                                                                    EventBlock?>
                                        >();
        day_cells = new GtkCal.MonthCell[7];

        for ( int i = 0; i < 7; i++ ) {
            day_cells[i] = new GtkCal.MonthCell ();
            day_cells[i].set_parent (this);
            day_cells[i].show_overflow.connect (on_month_cell_show_overflow_cb);
        }
    }

    ~MonthViewRow() {
        for ( int i = 0; i < 7; i++ ) {
            day_cells[i].unparent ();
        }

        remove_event_widgets ();
    }

    private void remove_event_widgets () {
        for ( int i = 0; i < events.get_n_items (); i++ ) {
            var event = (GtkCal.Event) events.get_item (i);
            var blocks = layout_blocks.get (event);
            if (blocks == null) {
                continue;
            }
            for ( int j = 0; j < blocks.size; j++ ) {
                var block = blocks[j];
                //block.event_widget.dispose();
                block.event_widget.unparent ();
            }
        }
    }

    public void update_style_for_date (DateTime date) {
        DateTime start = range.start;

        for ( int i = 0; i < 7; i++ ) {
            DateTime cell_date = start.add_days (i);
            bool different_month = cell_date.get_year () != date.get_year () ||
                                   cell_date.get_month () != date.get_month ();
            day_cells[i].different_month = different_month;
        }
    }

    private int compare_events_cb (Object a, Object b) {
        /** TODO: multiday **/
        return GtkCal.Event.compare ((GtkCal.Event) a, (GtkCal.Event) b);
    }

    public void add_event (GtkCal.Event event) {
        events.insert_sorted (event, compare_events_cb);
        recalculate_layout_blocks ();
        dump_layout_blocks ();
    }

    private void dump_layout_blocks () {
#if ENABLE_TRACE
        debug ("dump_layout_blocks");
        for ( int i = 0; i < events.get_n_items (); i++ ) {
            var event = (GtkCal.Event) events.get_item (i);
            var blocks = layout_blocks.get (event);
            debug ("  event %d: %s; %d blocks", i, event.uid, blocks.size);
            for ( int j = 0; j < blocks.size; j++ ) {
                var block = blocks[j];
                debug ("    block %d: length %d, cell %d", j, block.length,
                       block.cell);
            }
        }
#endif
    }

    private void recalculate_layout_blocks () {
        remove_event_widgets ();
        uint events_at_weekday[7] = { 0, };
        uint n_events = events.get_n_items ();
        var range_start = range.start;
        layout_blocks = new Gee.HashMap<GtkCal.Event, Gee.ArrayList<GtkCal.
                                                                    EventBlock?>
                                        >();

        for ( int i = 0; i < n_events; i++ ) {
            var blocks = new Gee.ArrayList<GtkCal.EventBlock?>();
            var event = (GtkCal.Event) events.get_item (i);
            int first_cell, last_cell;
            calculate_event_cells (event, out first_cell, out last_cell);
#if ENABLE_TRACE
            debug ("event %s spans cells %d to %d", event.uid, first_cell,
                   last_cell);
#endif
            GtkCal.EventBlock? block = null;
            int index = -1;
            for ( int cell = first_cell; cell <= last_cell; cell++ ) {
                events_at_weekday[cell]++;
                if (block == null) {
                    var event_widget = new GtkCal.EventWidget (event);
                    if (!event.allday && !event.multiday) {
                        event_widget.timestamp_policy = GtkCal.TimestampPolicy.
                                                        START;
                    }

                    setup_child_widget (event_widget);

                    block = new GtkCal.EventBlock ();
                    block.event_widget = event_widget;
                    block.length = 1;
                    block.visible = true;
                    block.cell = cell;

                    blocks.add (block);
                    index = blocks.size - 1;
                } else if (cell > first_cell && events_at_weekday[cell] !=
                           events_at_weekday[cell - 1]) {
                    var event_widget = GtkCal.EventWidget.clone ((GtkCal.
                                                                  EventWidget)
                                                                 block.
                                                                 event_widget);
                    setup_child_widget (event_widget);

                    block = new GtkCal.EventBlock ();
                    block.event_widget = event_widget;
                    block.length = 1;
                    block.visible = true;
                    block.cell = cell;

                    blocks.add (block);
                    index = blocks.size - 1;
                } else {
                    block.length++;
                    blocks[index] = block;
                }
            }

            /** Adjust slanted edges **/

            if (event.multiday) {
#if ENABLE_TRACE
                debug ("event is multiday (%s)", event.range.to_string ());
#endif
                var adjusted_range_start = new DateTime (event.date_start.
                                                         get_timezone (),
                                                         range_start.get_year ()
                                                         ,
                                                         range_start.get_month
                                                             (),
                                                         range_start.
                                                         get_day_of_month (),
                                                         0, 0, 0.0);

                for ( int j = 0; j < blocks.size; j++ ) {
                    block = blocks[j];
                    var block_start = adjusted_range_start.add_days (block.cell)
                    ;
                    var block_end = adjusted_range_start.add_days (block.cell +
                                                                   block.length)
                    ;
                    ((GtkCal.EventWidget) block.event_widget).date_start =
                        block_start;
                    ((GtkCal.EventWidget) block.event_widget).date_end =
                        block_end;
                }
            }
#if ENABLE_TRACE
            debug ("event %s spans %d blocks", event.uid, blocks.size);
#endif
            layout_blocks.set (event, blocks);
        }
    }

    private void setup_child_widget (Gtk.Widget widget) {
        widget.insert_after (this, day_cells[6]);
        ((GtkCal.EventWidget) widget).activate.connect (
            on_event_widget_activated_cb);
    }

    private void calculate_event_cells (GtkCal.Event event, out int first_cell,
                                        out int last_cell) {
        /** TODO: all day **/
        first_cell = int.max (GtkCal.date_time_compare_date (event.date_start,
                                                             range.start), 0);
        last_cell = GtkCal.date_time_compare_date (event.date_end, range.start).
                    clamp (first_cell, 6);
    }

    /** Signal handling **/
    public signal void event_activated (GtkCal.Event event);

    private void on_event_widget_activated_cb (GtkCal.EventWidget event_widget)
    {
        event_activated (event_widget.event);
    }

    /** Gtk.Widget overrides **/

    public override void measure (Gtk.Orientation orientation,
                                  int for_size,
                                  out int out_minimum,
                                  out int out_natural,
                                  out int out_minimum_baseline,
                                  out int out_natural_baseline) {
        int minimum = 0;
        int natural = 0;

        for ( int i = 0; i < 7; i++ ) {
            int child_minimum;
            int child_natural;

            day_cells[i].measure (orientation,
                                  for_size,
                                  out child_minimum,
                                  out child_natural,
                                  null, null);

            minimum += child_minimum;
            natural += child_natural;
        }

        out_minimum = minimum;
        out_natural = natural;
        out_minimum_baseline = -1;
        out_natural_baseline = -1;
    }

    public override void size_allocate (int width,
                                        int height,
                                        int baseline) {
        base.size_allocate (width, height, baseline);
        bool is_ltr = get_direction () != Gtk.TextDirection.RTL;
        double cell_width = width / 7.0;

        for ( int i = 0; i < 7; i++ ) {
            Gtk.Allocation allocation = Gtk.Allocation ();
            allocation.x = (int) Math.round (cell_width * i);
            allocation.y = 0;
            allocation.width = (int) Math.round (cell_width * (i + 1)) -
                               allocation.x;
            allocation.height = height;

            GtkCal.MonthCell cell = is_ltr ? day_cells[i] : day_cells[7 - i - 1]
            ;

            var transform = new Gsk.Transform ();
            transform = transform.translate ({ allocation.x, allocation.y });
            cell.allocate (allocation.width, allocation.height, baseline,
                           transform);
        }

        double cell_y[7];
        var overflows = prepare_layout_blocks ();
        for ( uint i = 0; i < 7; i++ ) {
            cell_y[i] = day_cells[i].get_header_height ();
        }

        uint n_events = events.get_n_items ();

        for ( uint i = 0; i < n_events; i++ ) {
            var event = (GtkCal.Event) events.get_item (i);
            var blocks = layout_blocks.get (event);

            for ( int block_index = 0; block_index < blocks.size; block_index++
                  ) {
                var block = blocks[block_index];
                var allocation = Gtk.Allocation ();

                allocation.x = (int) ((is_ltr ? block.cell : 7 - block.cell -
                                       block.length) * cell_width);
                allocation.y = (int) cell_y[block.cell];
                allocation.width = (int) (block.length * cell_width);
                allocation.height = block.height;

                block.event_widget.set_child_visible (block.visible);

                var transform = new Gsk.Transform ();
                transform = transform.translate ({ allocation.x, allocation.y })
                ;
                block.event_widget.allocate (allocation.width, allocation.height
                                             , baseline, transform);
                for ( uint j = 0; j < block.length; j++ ) {
                    cell_y[block.cell + j] += block.height;
                }
            }
        }

        for ( uint i = 0; i < 7; i++ ) {
            day_cells[i].n_overflow = (int) overflows[i];
        }
    }

    private uint[] prepare_layout_blocks () {
        uint overflows[7] = { 0, };

        Gee.ArrayList<Gee.ArrayList<GtkCal.EventBlock?> > blocks_per_day = new
                                                                           Gee.
                                                                           ArrayList
                                                                           <Gee.
                                                                            ArrayList
                                                                            <
                                                                                GtkCal
                                                                                .
                                                                                EventBlock
                                                                                ?> >();
        bool cell_will_overflow[7] = { false, };
        int available_height_without_overflow[7] = { 0, };
        int available_height_with_overflow[7] = { 0, };
        int weekday_heights[7] = { 0, };
        uint n_events = events.get_n_items ();

        for ( int i = 0; i < 7; i++ ) {
            int overflow_height = day_cells[i].get_overflow_height ();
            int content_space = day_cells[i].get_content_space ();

            available_height_without_overflow[i] = content_space;
            available_height_with_overflow[i] = content_space - overflow_height;
            blocks_per_day.add (new Gee.ArrayList<GtkCal.EventBlock?>());
        }
        for ( int i = 0; i < n_events; i++ ) {
            var event = (GtkCal.Event) events.get_item (i);
            var blocks = layout_blocks.get (event);

            var new_blocks = new Gee.ArrayList<GtkCal.EventBlock?>();
            for ( int block_index = 0; block_index < blocks.size; block_index++
                  ) {
                var block = blocks.get (block_index);

                block.visible = true;
                block.event_widget.measure (Gtk.Orientation.VERTICAL, -1, null,
                                            out block.height, null, null);
                for ( int j = 0; j < block.length; j++ ) {
                    int cell = block.cell + j;
                    blocks_per_day[cell].add (block);
                    weekday_heights[cell] += block.height;
                    cell_will_overflow[cell] |= weekday_heights[cell] >
                                                available_height_without_overflow
                                                [cell];
                }
                new_blocks.add (block);
            }
            layout_blocks.set (event, new_blocks);
        }
        for ( int cell = 0; cell < 7; cell++ ) {
            for ( int block_index = 0; block_index < blocks_per_day[cell].size;
                  block_index++ ) {
                var block = blocks_per_day[cell][block_index];
                if (block.cell != cell) {
                    continue;
                }

                for ( int block_cell = cell; block_cell < cell + block.length;
                      block_cell++ ) {
                    int available_height;
                    if (cell_will_overflow[block_cell]) {
                        available_height = available_height_with_overflow[
                            block_cell];
                    } else {
                        available_height = available_height_without_overflow[
                            block_cell];
                    }
                    block.visible &= available_height > block.height;
                }

                for ( int block_cell = cell; block_cell < cell + block.length;
                      block_cell++ ) {
                    if (block.visible) {
                        available_height_with_overflow[block_cell] -= block.
                                                                      height;
                        available_height_without_overflow[block_cell] -= block.
                                                                         height;
                    } else {
                        overflows[block_cell]++;
                    }
                }
            }
        }

        return overflows;
    }

    /** Signals **/
    public signal void show_overflow (GtkCal.MonthCell cell);

    /** Callbacks **/
    public void on_month_cell_show_overflow_cb (GtkCal.MonthCell cell) {
        show_overflow (cell);
    }
}
