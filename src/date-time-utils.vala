namespace GtkCal {
    public int date_time_compare_date (DateTime a, DateTime b) {
        Date da = Date ();
        da.set_dmy ((DateDay) a.get_day_of_month (), a.get_month (),
                    (DateYear) a.get_year ());
        Date db = Date ();
        db.set_dmy ((DateDay) b.get_day_of_month (), b.get_month (),
                    (DateYear) b.get_year ());

        return db.days_between (da);
    }

    [Flags]
    private enum WeekDay {
        INVALID   = 0,
        SUNDAY    = 1 << 0,
        MONDAY    = 1 << 1,
        TUESDAY   = 1 << 2,
        WEDNESDAY = 1 << 3,
        THURSDAY  = 1 << 4,
        FRIDAY    = 1 << 5,
        SATURDAY  = 1 << 6
    }

    public DateTime date_time_get_start_of_week (DateTime date) {
        int first_weekday = get_first_weekday ();
        int weekday = (int) date.get_day_of_week () % 7;
        int n_days_after_week_start = (7 + weekday - first_weekday) % 7;

        DateTime start_of_week = date.add_days (-n_days_after_week_start);
        DateTime rtn = new DateTime.local (
            start_of_week.get_year (),
            start_of_week.get_month (),
            start_of_week.get_day_of_month (),
            0, 0, 0.0
            );
        return rtn;
    }

    public ICal.Time date_time_to_icaltime (DateTime dt) {
        var idt = new ICal.Time.null_time ();

        idt.set_date (dt.get_year (), dt.get_month (), dt.get_day_of_month ());
        idt.set_time (dt.get_hour (), dt.get_minute (), dt.get_second ());
        idt.set_is_date (idt.get_hour () == 0 && idt.get_minute () == 0 &&
                         idt.get_second () == 0);
        return idt;
    }

    public DateTime icaltime_to_date_time (ICal.Time idt) {
        string tzid = idt.get_timezone ().get_tzid ();
        if (tzid == null) {
            tzid = "UTC";
        }

        var tz = new TimeZone.identifier (tzid);
        var dt = new DateTime (tz,
                               idt.get_year (),
                               idt.get_month (),
                               idt.get_day (),
                               idt.get_hour (),
                               idt.get_minute (),
                               idt.get_second ());
        return dt;
    }

    public bool date_time_is_date (DateTime date) {
        return date.get_hour () == 0 && date.get_minute () == 0 && date.
               get_seconds () == 0.0;
    }
}
