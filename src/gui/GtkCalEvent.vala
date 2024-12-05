public class GtkCal.Event : Object {
    private DateTime dt_start;
    private DateTime dt_end;

    public DateTime date_start {
        get {
            return dt_start;
        }
        set {
            dt_start = value;

            ICal.Time component_dt = GtkCal.date_time_to_icaltime (value);
            component.set_dtstart (component_dt);
        }
    }

    public DateTime date_end {
        get {
            return dt_end;
        }
        set {
            dt_end = value;

            ICal.Time component_dt = GtkCal.date_time_to_icaltime (value);
            component.set_dtend (component_dt);
        }
    }

    public string uid {
        get {
            return component.get_uid ();
        }
    }

    public string summary {
        get;
        construct;
    }

    public string description {
        get;
        construct;
    }

    public string location {
        get;
        construct;
    }

    private Gdk.RGBA _color = Gdk.RGBA ();

    public Gdk.RGBA color {
        get {
            return _color;
        }
        set {
            _color = value;
        }
    }

    public GtkCal.Range range {
        get;
        construct;
    }

    public bool allday {
        get;
        construct;
    }

    public bool multiday {
        get {
            DateTime start_date;
            DateTime end_date;
            int n_days;
            if (allday) {
                start_date = date_start;
                end_date = date_end;
                n_days = 1;
            } else {
                var inclusive_end_date = date_end.add_seconds (-1);
                start_date = date_start.to_local ();
                end_date = inclusive_end_date.to_local ();
                n_days = 0;
            }

            Date start = Date ();
            start.clear ();
            start.set_dmy ((DateDay) start_date.get_day_of_month (), start_date.
                           get_month (), (DateYear) start_date.get_year ());

            Date end = Date ();
            end.clear ();
            end.set_dmy ((DateDay) end_date.get_day_of_month (), end_date.
                         get_month (), (DateYear) end_date.get_year ());

            return start.days_between (end) > n_days;
        }
    }

    private ICal.Component _component;
    public ICal.Component component {
        get {
            return _component;
        }
        set construct {
            _component = value;
            date_start = GtkCal.icaltime_to_date_time (value.get_dtstart ());
            date_end = GtkCal.icaltime_to_date_time (value.get_dtend ());
        }
    }

    public Event(ICal.Component component) {
        Object (component: component);
    }

    construct {
        string zone_start = component.get_dtstart ().get_timezone ().get_tzid ()
        ;
        date_start = GtkCal.icaltime_to_date_time (component.get_dtstart ());
        bool start_is_all_day = GtkCal.date_time_is_date (date_start);

        range = new GtkCal.Range (date_start, date_end, GtkCal.RangeType.
                                  GTKCAL_RANGE_DEFAULT);
        summary = component.get_summary ();
        location = component.get_location ();
        description = component.get_description ();
        _color.parse ("green");

        if (date_end == null) {
            allday = true;
            date_end = date_start.add_days (1);
        } else {
            string zone_end = component.get_dtend ().get_timezone ().get_tzid ()
            ;
            date_end = GtkCal.icaltime_to_date_time (component.get_dtend ());
            bool end_is_all_day = GtkCal.date_time_is_date (date_end);
            allday = start_is_all_day && end_is_all_day;
        }
    }

    public static int compare (GtkCal.Event a, GtkCal.Event b) {
        /** TODO: all day **/
        int start_diff = a.dt_start.compare (b.dt_start);
        if (start_diff != 0) {
            return start_diff;
        } else {
            TimeSpan span_a = a.dt_start.difference (a.dt_end);
            TimeSpan span_b = b.dt_start.difference (b.dt_end);

            return (int) (span_b - span_a);
        }
    }
}
