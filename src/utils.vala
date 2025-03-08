namespace GtkCal {
    private Gee.ArrayList<Gdk.RGBA?> colors;
    private string color_css;
    private Adw.StyleManager style_manager;
    private Gtk.CssProvider style_provider;
    private Gtk.CssProvider extra_provider;
    private Gtk.CssProvider events_provider;

    public bool init () {
        debug("init GtkCal");
        colors = new Gee.ArrayList<Gdk.RGBA?>();
        color_css = "";
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/style.css");
        events_provider = new Gtk.CssProvider ();
        events_provider.load_from_resource ("/events.css");

        extra_provider = new Gtk.CssProvider ();

        style_manager = Adw.StyleManager.get_default();
        style_manager.notify["dark"].connect((s, p) => update_stylesheet());
        style_manager.notify["high_contrast"].connect((s, p) => update_stylesheet());

        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                   events_provider, Gtk.
                                                   STYLE_PROVIDER_PRIORITY_APPLICATION
                                                   + 1);
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                   style_provider, Gtk.
                                                   STYLE_PROVIDER_PRIORITY_APPLICATION
                                                   + 1);
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                   extra_provider, Gtk.
                                                   STYLE_PROVIDER_PRIORITY_APPLICATION
                                                   + 1);
        update_stylesheet ();
        return true;
    }

    private bool update_stylesheet() {
        bool dark = style_manager.dark;
        bool high_contrast = style_manager.high_contrast;

        debug("dark: %b; hc: %b", dark, high_contrast);
        if (dark) {
            if (high_contrast) {
                extra_provider.load_from_resource("/style-hc-dark.css");
            } else {
                extra_provider.load_from_resource("/style-dark.css");
            }
        } else {
            if (high_contrast) {
                extra_provider.load_from_resource("/style-hc.css");
            } else {
                extra_provider.load_from_string("");
            }
        }
        return true;
    }

    public bool add_color_to_css(Gdk.RGBA color) {
        if (color in colors) {
            return false;
        }
        colors.add(color);
        color_css = "";
        for ( int i = 0; i < colors.size; i++ ) {
            var _color = colors[i];
            var color_str = _color.to_string ();
            var color_id = Quark.from_string (color_str);
            color_css += ".color-%u { --event-bg-color: %s; }\n".printf (
                color_id
                ,
                color_str);
        }
        var color_provider = new Gtk.CssProvider ();
        color_provider.load_from_string (color_css);
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                   color_provider, Gtk.
                                                   STYLE_PROVIDER_PRIORITY_APPLICATION
                                                   + 1);
        return true;
    }

    public int get_first_weekday () {
        int week_1stday = 0;
        int first_weekday = Posix.NLTime.FIRST_WEEKDAY.to_string ()[0];
        int week_origin = (int) Posix.NLTime.WEEK_1STDAY.to_string ();

        if (week_origin == 19971130) { /* Sunday */
            week_1stday = 0;
        }else if (week_origin == 19971201) { /* Monday */
            week_1stday = 1;
        }else {
            warning ("Unknown value of WEEK_1STDAY");
        }
        int week_start = (week_1stday + first_weekday - 1) % 7;
        return week_start;
    }

    public string get_weekday (int day_no) {
        int[] ab_day = {
            Posix.NLItem.ABDAY_1,
            Posix.NLItem.ABDAY_2,
            Posix.NLItem.ABDAY_3,
            Posix.NLItem.ABDAY_4,
            Posix.NLItem.ABDAY_5,
            Posix.NLItem.ABDAY_6,
            Posix.NLItem.ABDAY_7,
        };
        return Posix.nl_langinfo (ab_day[day_no]);
    }

    public string get_month_name (int i) {
        int[] month_item = {
            Posix.NLItem.MON_1,
            Posix.NLItem.MON_2,
            Posix.NLItem.MON_3,
            Posix.NLItem.MON_4,
            Posix.NLItem.MON_5,
            Posix.NLItem.MON_6,
            Posix.NLItem.MON_7,
            Posix.NLItem.MON_8,
            Posix.NLItem.MON_9,
            Posix.NLItem.MON_10,
            Posix.NLItem.MON_11,
            Posix.NLItem.MON_12,
        };
        return Posix.nl_langinfo (month_item[i]);
    }

    private struct NoWorkDayPerLocale {
        string territory;
        WeekDay no_work_days;
    }

    const NoWorkDayPerLocale[] NO_WORK_DAY_PER_LOCALE = {
        { "AE", WeekDay.FRIDAY | WeekDay.SATURDAY } /* United Arab Emirates */,
        { "AF", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Afghanistan */,
        { "BD", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Bangladesh */,
        { "BH", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Bahrain */,
        { "BN", WeekDay.SUNDAY | WeekDay.FRIDAY } /* Brunei Darussalam */,
        { "CR", WeekDay.SATURDAY } /* Costa Rica */,
        { "DJ", WeekDay.FRIDAY } /* Djibouti */,
        { "DZ", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Algeria */,
        { "EG", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Egypt */,
        { "GN", WeekDay.SATURDAY } /* Equatorial Guinea */,
        { "HK", WeekDay.SATURDAY } /* Hong Kong */,
        { "IL", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Israel */,
        { "IQ", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Iraq */,
        { "IR", WeekDay.THURSDAY | WeekDay.FRIDAY } /* Iran */,
        { "KW", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Kuwait */,
        { "KZ", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Kazakhstan */,
        { "LY", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Libya */,
        { "MX", WeekDay.SATURDAY } /* Mexico */,
        { "MY", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Malaysia */,
        { "NP", WeekDay.SATURDAY } /* Nepal */,
        { "OM", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Oman */,
        { "QA", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Qatar */,
        { "SA", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Saudi Arabia */,
        { "SU", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Sudan */,
        { "SY", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Syria */,
        { "UG", WeekDay.SUNDAY } /* Uganda */,
        { "YE", WeekDay.FRIDAY | WeekDay.SATURDAY } /* Yemen */,
    };


    public bool is_workday (int day) {
        if (day > 6) {
            return false;
        }

        char territory[3] = { 0, };
        WeekDay no_work_days;
        no_work_days = WeekDay.SATURDAY | WeekDay.SUNDAY;
        string locale = Intl.setlocale (LocaleCategory.TIME);

        if (locale == null || locale.length < 5) {
            warning (
                "Locale is unset or lacks territory code, assuming Saturday and Sunday as non workdays");
            return !(((WeekDay) 1 << day) in no_work_days);
        }

        territory[0] = locale[3];
        territory[1] = locale[4];

        for ( int i = 0; i < NO_WORK_DAY_PER_LOCALE.length; i++ ) {
            if (NO_WORK_DAY_PER_LOCALE[i].territory == (string) territory) {
                no_work_days = NO_WORK_DAY_PER_LOCALE[i].no_work_days;
                break;
            }
        }
        return !(((WeekDay) 1 << day) in no_work_days);
    }

    private struct Service {
        string needle;
        string service_name;
    }

    const Service[] service_name_vtable = {
        { "meet.google.com", N_ ("Google Meet") },
        { "meet.jit.si", N_ ("Jitsi") },
        { "whereby.com", N_ ("Whereby") },
        { "zoom.us", N_ ("Zoom") },
        { "teams.microsoft.com", N_ ("Microsoft Teams") },
    };

    public string? get_service_name_from_url (string url) {
        for ( int i = 0; i < service_name_vtable.length; i++ ) {
            if (url.contains (service_name_vtable[i].needle)) {
                return gettext (service_name_vtable[i].service_name);
            }
        }

        return null;
    }
}

