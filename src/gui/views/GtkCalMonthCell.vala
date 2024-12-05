[GtkTemplate (ui = "/ui/gcal-month-cell.ui")]
public class GtkCal.MonthCell : Adw.Bin {
    static construct {
        set_css_name ("monthcell");
    }
    [GtkChild]
    private unowned Gtk.Label day_label;
    [GtkChild]
    private unowned Gtk.Label month_name_label;
    [GtkChild]
    private unowned Gtk.Box header_box;
    [GtkChild]
    private unowned Gtk.Button overflow_button;
    [GtkChild]
    private unowned Gtk.Inscription overflow_inscription;

    private DateTime _date;
    public DateTime date {
        get {
            return _date;
        }
        set {
            if (_date != null && GtkCal.date_time_compare_date (_date, value) ==
                0) {
                return;
            }
            _date = value;

            int day_of_month = value.get_day_of_month ();
            string text = "%d".printf (day_of_month);

            day_label.set_text (text);
            update_style_flags ();
            add_month_separators ();

            month_name_label.set_visible (day_of_month == 1);
            if (day_of_month == 1) {
                string month_name = value.format ("%b");
                month_name_label.set_text (month_name);
            }
            //update_weather();
        }
    }

    private void update_style_flags () {
        DateTime today = new DateTime.now_local ();
        int weekday = date.get_day_of_week ();

        if (GtkCal.date_time_compare_date (date, today) == 0) {
            add_css_class ("today");
        } else {
            remove_css_class ("today");
        }

        if (GtkCal.is_workday (weekday)) {
            add_css_class ("workday");
        } else {
            remove_css_class ("workday");
        }
    }

    private void add_month_separators () {
        remove_css_class ("separator-top");
        remove_css_class ("separator-side");
        int day_of_month = date.get_day_of_month ();

        if (day_of_month > 1 && day_of_month <= 7) {
            add_css_class ("separator-top");
        } else if (day_of_month == 1) {
            add_css_class ("separator-top");
            add_css_class ("separator-side");
        }
    }

    private bool different;
    public bool different_month {
        get {
            return different;
        }
        set {
            if (different == value) {
                return;
            }

            different = value;
            if (different) {
                add_css_class ("out-of-month");
            } else {
                remove_css_class ("out-of-month");
            }
        }
    }

    private int _n_overflow;
    public int n_overflow {
        get {
            return _n_overflow;
        }
        set {
            if (value == _n_overflow) {
                return;
            }
            _n_overflow = value;
            overflow_button.set_sensitive (value > 0);

            if (value > 0) {
                string text = "+%d".printf (value);
                overflow_inscription.set_text (text);
            } else {
                overflow_inscription.set_text ("");
            }
        }
    }

    public int get_header_height () {
        var context = header_box.get_style_context ();
        var padding = context.get_padding ();
        var border = context.get_border ();

        return header_box.get_height () +
               header_box.get_margin_top () +
               header_box.get_margin_bottom () +
               padding.top + padding.bottom +
               border.top + border.bottom;
    }

    public int get_overflow_height () {
        return overflow_button.get_height ();
    }

    public int get_content_space () {
        var context = get_style_context ();
        var padding = context.get_padding ();
        var border = context.get_border ();

        return get_height () -
               get_header_height () -
               padding.top - padding.bottom -
               border.top - border.bottom;
    }

    /** Signals **/
    public signal void show_overflow ();

    /** Callbacks **/
    [GtkCallback]
    public void overflow_button_clicked_cb () {
        show_overflow ();
    }
}
