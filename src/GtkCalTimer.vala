namespace GtkCal {
    class Timer : Source {
        public int64 default_duration;

        public int64 last_event = -1;

        public Timer (int64 default_duration) {
            base ();

            MainContext context = MainContext.default ();

            attach (context);
        }

        public void schedule_next () {
            int64 now = get_time ();
            int64 next = last_event + default_duration * 1000000;

            if (next > now) {
                set_ready_time (next);
            } else {
                set_ready_time (0);
            }
        }

        public bool is_running () {
            return get_ready_time () >= 0;
        }

        public void reset () {
            if (!is_running ()) {
                return;
            }

            last_event = get_time ();
            schedule_next ();
        }

        public void start () {
            if (is_running ()) {
                return;
            }

            last_event = get_time ();
            schedule_next ();
        }

        public void stop () {
            if (!is_running ()) {
                return;
            }

            set_ready_time (-1);
        }


        /* Overrides */
        public override bool dispatch (SourceFunc? user_callback) {
            bool result = true;

            last_event = get_time ();

            if (user_callback != null) {
                result = user_callback ();
            }

            schedule_next ();

            return result;
        }
    }
}
