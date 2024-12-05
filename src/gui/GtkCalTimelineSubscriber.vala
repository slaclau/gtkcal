public interface GtkCal.TimelineSubscriber : Object {
    public signal void range_changed ();

    public abstract GtkCal.Range range { owned get; }

    public abstract void add_event (GtkCal.Event event);
    public abstract void remove_event (GtkCal.Event event);
}
