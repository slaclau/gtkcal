public interface GtkCal.View : Gtk.Widget {
    public abstract DateTime date {
        get;
        set;
        default = null;
    }

    public signal void event_activated (GtkCal.Event event) {
        debug ("event activated: %s %s", event.summary, event.range.to_string ()
               );
    }
}
