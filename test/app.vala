int main (string[] argv) {
    // Create a new application
    var app = new Adw.Application ("com.example.GtkApplication", GLib.
                                   ApplicationFlags.FLAGS_NONE);

    var ical_string_test =
        "BEGIN:VEVENT
DTSTART:20250408T123000Z
DTEND:20250408T210000Z
SUMMARY:s
DESCRIPTION:d
X-ICON-NAME:application-community-symbolic
END:VEVENT";
    var ical_string_test2 =
        "BEGIN:VEVENT
DTSTART:20250408T123000Z
DTEND:20250408T210000Z
SUMMARY:s
DESCRIPTION:d
END:VEVENT";

    var ical_string =
        "BEGIN:VEVENT
DTSTAMP:20241203T123000Z
UID:uid1@example.com
DTSTART:20241203T123000Z
DTEND:20241203T210000Z
SUMMARY:s
DESCRIPTION:d
LOCATION:Home
END:VEVENT";

    var ical_string1 =
        "BEGIN:VEVENT
DTSTAMP:20241203T123000Z
UID:uid1@example.com
DTSTART:20241203T123000Z
DTEND:20241203T210000Z
SUMMARY:s1
DESCRIPTION:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam quis libero eu elit ullamcorper auctor a et nulla. Aliquam venenatis nulla sit amet facilisis faucibus. Duis eleifend aliquet purus, in fermentum eros tempor vitae. In nec congue lacus. Nam imperdiet, erat eget iaculis condimentum, orci eros luctus dui, ut tincidunt.
LOCATION:https://meet.google.com/abc-mnop-xyz
END:VEVENT";

    var ical_string2 =
        "BEGIN:VEVENT
DTSTAMP:20241205T123000Z
UID:uid2@example.com
DTSTART:20241205T123000Z
DTEND:20241207T210000Z
SUMMARY:s2
DESCRIPTION:d2
END:VEVENT";

    var ical_string2a =
        "BEGIN:VEVENT
DTSTAMP:20241206T123000Z
UID:uid2@example.com
DTSTART:20241206T123000Z
DTEND:20241206T210000Z
SUMMARY:s2a
DESCRIPTION:d2a
END:VEVENT";

    var ical_string3 =
        "BEGIN:VEVENT
DTSTAMP:20241204T123000Z
UID:uid3@example.com
DTSTART:20241204T123000Z
DTEND:20241205T210000Z
SUMMARY:s3
DESCRIPTION:d3
END:VEVENT";

    string[] ical_strings = { ical_string, ical_string1, ical_string,
                              ical_string, ical_string, ical_string,
                              ical_string, ical_string2, ical_string2a,
                              ical_string2, ical_string3, ical_string_test,
                              ical_string_test2 };
    string[] colors = { "black", "red", "blue", "yellow" };

    app.activate.connect (() => {
        GtkCal.init ();
        GtkCal.activate_weather_service (true);
        var window = new Adw.ApplicationWindow (app);
        GtkCal.MonthView month_view = new GtkCal.MonthView ();
        for ( int i = 0; i < ical_strings.length; i++ ) {
            var ical_event = new ICal.Component.from_string (ical_strings[i]);
            var event = new GtkCal.Event (ical_event);
            var _col = Gdk.RGBA ();
            _col.parse (colors[Random.int_range (0, colors.length)]);
            event.color = _col;
            month_view.add_event (event);
        }

        window.set_content (month_view);
        window.present ();

        string color_css = "";
        for ( int i = 0; i < colors.length; i++ ) {
            var color = Gdk.RGBA ();
            color.parse (colors[i]);
            var color_str = color.to_string ();
            var color_id = Quark.from_string (color_str);
            color_css += ".color-%u { --event-bg-color: %s; }\n".printf (
                color_id
                ,
                color_str);
        }

        var color_provider = new Gtk.CssProvider ();
        color_provider.load_from_string (color_css);

        Gtk.StyleContext.add_provider_for_display (window.get_display (),
                                                   color_provider, Gtk.
                                                   STYLE_PROVIDER_PRIORITY_APPLICATION
                                                   + 1);
    });
    return app.run (argv);
}
