class GtkCal.OverflowBin : Gtk.Widget, Gtk.Buildable {
    private Gtk.SizeRequestMode _request_mode = Gtk.SizeRequestMode.
                                                CONSTANT_SIZE;
    public Gtk.SizeRequestMode request_mode {
        get {
            return _request_mode;
        }
        set {
            GtkCal.OverflowBinLayout layout_manager = (GtkCal.OverflowBinLayout)
                                                      get_layout_manager ();
            layout_manager.request_mode = value;
            _request_mode = value;
        }
    }

    public Gtk.Widget child { get; set; }

    public void add_child (Gtk.Builder builder, Object _child, string? type) {
#if ENABLE_TRACE
        debug ("adding %p to overflow bin", _child);
#endif
        if (child is Gtk.Widget) {
            child = (Gtk.Widget) _child;
        } else {
            base.add_child (builder, _child, type);
        }
    }

    static construct {
        set_layout_manager_type (typeof (GtkCal.OverflowBinLayout));
    }

    ~OverflowBin() {
        Gtk.Widget widget = get_first_child ();
        while (widget != null) {
            widget.unparent ();
            widget = widget.get_next_sibling ();
        }
    }
}
