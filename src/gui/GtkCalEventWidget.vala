const int LOCATION_MAX_LEN = 50;
const int DESC_MAX_CHAR = 200;

[GtkTemplate (ui = "/ui/gcal-event-widget.ui")]
class GtkCal.EventWidget : Gtk.Widget, Gtk.Orientable {
    [GtkChild]
    unowned Gtk.Inscription summary_inscription;
    [GtkChild]
    unowned Gtk.Label timestamp_label;
    [GtkChild]
    unowned Gtk.Image icon;

    public Gtk.Orientation orientation { get; set; }
    public GtkCal.TimestampPolicy timestamp_policy { get; set; default = GtkCal.
                                                                         TimestampPolicy
                                                                         .NONE;
    }

    private DateTime dt_start;
    private DateTime dt_end;

    public DateTime date_start {
        get {
            return dt_start;
        }
        set {
            if (value != dt_start && (dt_start == null || value == null ||
                                      (dt_start != null && value != null && !
                                       dt_start.equal (value)))) {
                if (value != null && value.compare (event.date_start) < 0) {
                    return;
                }

                dt_start = value;

                update_style ();
            }
        }
    }

    public DateTime date_end {
        get {
            return dt_end;
        }
        set {
            if (value != dt_end && (dt_end == null || value == null ||
                                    (dt_end != null && value != null && !dt_end.
                                     equal (value)))) {
                if (value != null && value.compare (event.date_end) > 0) {
                    return;
                }

                dt_end = value;

                update_style ();
            }
        }
    }

    static construct {
        set_css_name ("event");
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }
    public EventWidget(GtkCal.Event event) {
        Object (event: event);
    }

    public static GtkCal.EventWidget clone (GtkCal.EventWidget original) {
        return new GtkCal.EventWidget (original.event);
    }
    construct {
        set_cursor_from_name ("pointer");
        orientation = Gtk.Orientation.HORIZONTAL;

        notify["timestamp-policy"].connect_after (update_timestamp);
    }
    ~EventWidget() {
        Gtk.Widget widget = get_first_child ();
        while (widget != null) {
            widget.unparent ();
            widget = widget.get_next_sibling ();
        }
    }
    private GtkCal.Event _event;
    public GtkCal.Event event {
        get {
            return _event;
        }
        construct {
            _event = value;
            date_start = event.date_start;
            date_end = event.date_end;

            update_color ();

            event.notify["color"].connect_after (update_color);
            event.notify["summary"].connect_after (queue_draw);
            event.notify["icon_name"].connect_after (queue_draw);

            set_event_tooltip ();

            event.bind_property ("summary", summary_inscription, "text",
                                 BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE
                                 );
            event.bind_property ("icon-name", icon, "icon-name",
                                 BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE
                                 );
            event.bind_property ("icon-name", icon, "visible",
                                 BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE
                                 ,
                                 (binding, srcval, ref targetval) => {
                string src = (string) srcval;
                targetval.set_boolean (src == null ? false : true);
                return true;
            }
                                 );

            update_style ();
            update_timestamp ();
        }
    }

    private string css_class;

    private void update_color () {
        var color = event.color;
        var now = new DateTime.now_local ();
        int date_compare = date_end.compare (now);

        if (date_compare < 0) {
            add_css_class ("dim-label");
        } else {
            remove_css_class ("dim-label");
        }

        if (css_class != null) {
            remove_css_class (css_class);
        }

        string color_str = color.to_string ();
        Quark color_id = Quark.from_string (color_str);
        css_class = "color-%d".printf ((int) color_id);
        add_css_class (css_class);

        double intensity = color.red * 0.30 + color.green * 0.59 + color.blue *
                           0.11;

        if (intensity > 0.5) {
            remove_css_class ("color-dark");
            add_css_class ("color-light");
        } else {
            remove_css_class ("color-light");
            add_css_class ("color-dark");
        }
    }

    private void set_event_tooltip () {
        string tooltip_mesg = "<b>%s</b>".printf (Markup.escape_text (event.
                                                                      summary));
        string start, end;
        bool is_ltr = get_direction () != Gtk.TextDirection.RTL;

        if (event.allday) {
            if (event.multiday) {
                start = event.date_start.format ("%x");
                end = event.date_end.format ("%x");
            } else {
                start = event.date_start.format ("%x");
                end = "";
            }
        } else {
            var tt_start = event.date_start.to_local ();
            var tt_end = event.date_end.to_local ();

            if (event.multiday) {
                /** TODO: 24/12 hr **/
                if (is_ltr) {
                    start = tt_start.format ("%x %R");
                    end = tt_end.format ("%x %R");
                } else {
                    start = tt_start.format ("%R %x");
                    end = tt_end.format ("%R %x");
                }
            } else {
                /** TODO: 24/12 hr **/
                if (is_ltr) {
                    start = tt_start.format ("%x %R");
                    end = tt_end.format ("%R");
                } else {
                    start = tt_start.format ("%R %x");
                    end = tt_end.format ("%R");
                }
            }
        }

        if (event.allday && !event.multiday) {
            tooltip_mesg += "\n%s".printf (start);
        } else {
            tooltip_mesg += "\n%s - %s".printf (is_ltr ? start : end, is_ltr ?
                                                end : start);
        }

        string location;

        if (event.location != null) {
            location = event.location.strip ();
            if (location != null && location[0] != '\0') {
                try {
                    Uri guri = Uri.parse (location, Soup.HTTP_URI_FLAGS |
                                          UriFlags.PARSE_RELAXED);
                    string service_name = GtkCal.get_service_name_from_url (
                        location);
                    string str = "";
                    if (service_name != null) {
                        str += _ ("\n\nOn %s").printf (service_name);
                    } else {
                        string truncated_location = location;
                        if (truncated_location.length > LOCATION_MAX_LEN) {
                            truncated_location = truncated_location[0 :
                                                                    LOCATION_MAX_LEN
                                                                    - 1];
                            truncated_location += "…";
                        }
                        str += _ ("\n\nAt %s").printf (truncated_location);
                    }
                    tooltip_mesg += Markup.escape_text (str);
                } catch (UriError e) {
                    tooltip_mesg += Markup.escape_text (_ ("\n\nAt %s").printf (
                                                            location));
                }
            }
        }

        if (event.description.length > 0) {
            if (event.description.length > DESC_MAX_CHAR) {
                tooltip_mesg += Markup.escape_text ("\n\n%s".printf (event.
                                                                     description
                                                                     [0 :
                                                                      DESC_MAX_CHAR
                                                                      - 1] +
                                                                     "…"));
            } else {
                tooltip_mesg += Markup.escape_text ("\n\n%s".printf (event.
                                                                     description));
            }
        }



        set_tooltip_markup (tooltip_mesg);
    }

    private void update_timestamp () {
        string str = null;

        if (event != null && timestamp_policy != GtkCal.TimestampPolicy.NONE) {
            DateTime time;
            if (timestamp_policy == GtkCal.TimestampPolicy.START) {
                time = event.date_start;
            } else {
                time = event.date_end;
            }

            if (event.allday || event.multiday) {
                str = time.format ("%a %B %e");
            } else { // TODO: 24/12 hr
                str = time.format ("%R");
            }
        }

        timestamp_label.visible = str != null;
        timestamp_label.label = str;
    }

    private void update_style () {
        remove_css_class ("slanted");
        remove_css_class ("slanted-start");
        remove_css_class ("slanted-end");
        remove_css_class ("timed");

        bool slanted_start = date_start != null && event.date_start.compare (
            date_start) != 0;
        bool slanted_end = date_end != null && event.date_end.compare (date_end)
                           != 0;

        if (slanted_start && slanted_end) {
            add_css_class ("slanted");
        } else if (slanted_start) {
            add_css_class ("slanted-start");
        } else if (slanted_end) {
            add_css_class ("slanted-end");
        }

        if (orientation == Gtk.Orientation.HORIZONTAL) {
            remove_css_class ("vertical");
            add_css_class ("horizontal");
        } else {
            remove_css_class ("horizontal");
            add_css_class ("vertical");
        }
        bool timed = !event.allday && !event.multiday;

        if (timed) {
            add_css_class ("timed");
        }
    }

    [GtkCallback]
    public void on_click_gesture_pressed_cb (Gtk.GestureClick click_gesture, int
                                             n, double x, double y) {
        click_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    }

    [GtkCallback]
    public void on_click_gesture_release_cb (Gtk.GestureClick click_gesture, int
                                             n, double x, double y) {
        click_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
        activate ();
    }

    public new signal void activate ();
}
