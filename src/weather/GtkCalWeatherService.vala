int GTKCAL_WEATHER_CHECK_INTERVAL_RENEW_DEFAULT = (3 * 60 * 60); /* seconds */
int GTKCAL_WEATHER_CHECK_INTERVAL_NEW_DEFAULT = (5 * 60); /* seconds */
int GTKCAL_WEATHER_VALID_TIMESPAN_DEFAULT = (24 * 60 * 60); /* seconds */
int GTKCAL_WEATHER_FORECAST_MAX_DAYS_DEFAULT = 5;
int DAY_SECONDS = (24 * 60 * 60);

namespace GtkCal {
    struct WeatherIconInfo {
        string name;
        bool night_support;
    }
    class WeatherService : Object {
        private TimeZone? timezone;

        private int use_count = 0;

        /* timers */
        private int check_interval_new =
            GTKCAL_WEATHER_CHECK_INTERVAL_NEW_DEFAULT;
        private int check_interval_renew =
            GTKCAL_WEATHER_CHECK_INTERVAL_RENEW_DEFAULT;
        private GtkCal.Timer duration_timer = new GtkCal.Timer (
            GTKCAL_WEATHER_CHECK_INTERVAL_NEW_DEFAULT);
        private GtkCal.Timer midnight_timer = new GtkCal.Timer (24 * 60 * 60);

        /* network monitoring */
        private long network_changed_sid;

        /* locations */
        private GWeather.Location? location = null;
        private GClue.Simple location_service;
        private Cancellable location_cancellable = new Cancellable ();
        private bool location_service_running = false;

        /* weather */
        private int64 weather_infos_updated = -1;
        private Gee.ArrayList<WeatherInfo> weather_infos = new Gee.ArrayList<
            WeatherInfo> ();
        private int valid_timespan = GTKCAL_WEATHER_VALID_TIMESPAN_DEFAULT;
        private GWeather.Info? gweather_info = null;
        public int max_days = GTKCAL_WEATHER_FORECAST_MAX_DAYS_DEFAULT;

        private bool active;
        private bool weather_service_running;
        private bool weather_is_stale;


        construct {
            duration_timer.set_callback (on_duration_timer_timeout);
            midnight_timer.set_callback (on_midnight_timer_timeout);

            network_changed_sid = (long) (NetworkMonitor.get_default ().
                                          network_changed.connect (
                                              on_network_changed_cb));
        }


        public WeatherInfo? get_weather_info_for_date (Date date) {
            Time tm;
            date.to_time (out tm);
            foreach ( WeatherInfo info in weather_infos ) {
                info.date.to_time (out tm);
                if (info.date.compare (date) == 0) {
                    return info;
                }
            }
            return null;
        }

        /* Auxiliary functions */
        private void update_gclue_location (GClue.Location location) {
            GWeather.Location wlocation = null;

            if (location != null) {
                GWeather.Location wworld = GWeather.Location.get_world ();
                wlocation = wworld.find_nearest_city (location.latitude,
                                                      location.longitude);
            }

            update_location (wlocation);
        }

        private void update_location (GWeather.Location location) {
            if (duration_timer.is_running ()) {
                duration_timer.stop ();
            }

            if (location == null) {
                debug ("no location retrieved");
                update_weather (null, false);
            } else {
                debug ("update location to %s", location.get_name ());

                gweather_info = new GWeather.Info (location);
                gweather_info.contact_info = "https://example.com";
                gweather_info.application_id = "com.example.GtkApplication";
                gweather_info.enabled_providers = GWeather.Provider.METAR |
                                                  GWeather.Provider.MET_NO |
                                                  GWeather.Provider.OWM;

                gweather_info.updated.connect (on_gweather_update_cb);

                update_weather (null, false);
                gweather_info.update ();

                start_timer ();
            }
        }

        private void update_weather (GWeather.Info? info, bool
                                     reuse_old_on_error) {
            unowned SList gwforecast = null;

            if (info == null) {
                debug ("could not retrieve valid weather");
            } else if (info.is_valid ()) {
                debug ("received valid weather");
                gwforecast = info.get_forecast_list ();
            } else {
                string location_name = info.get_location_name ();
                debug ("could not retrieve valid weather for %s", location_name)
                ;
            }

            if (gwforecast == null && weather_infos_updated >= 0) {
                if (!reuse_old_on_error || !has_valid_weather_infos ()) {
                    weather_infos.clear ();
                    weather_infos_updated = -1;

                    weather_changed ();
                }
            } else if (gwforecast != null) {
                weather_infos.clear ();

                weather_infos = preprocess_gweather_reports (gwforecast);
                weather_infos_updated = get_monotonic_time ();

                weather_changed ();
            }
        }

        private Gee.ArrayList<WeatherInfo>? preprocess_gweather_reports (SList<
                                                                             GWeather
                                                                             .
                                                                             Info>
                                                                         samples)
        {
            debug ("preprocessing weather reports");
            Date cur_gdate;
            int64 today_unix;
            int64 unix_now;

            GWeather.Info first_tomorrow = null;
            long first_tomorrow_dtime = -1;


            if (max_days <= 0) {
                return null;
            }

            if (!get_time_day_start (out cur_gdate, out today_unix, out unix_now
                                     )) {
                return null;
            }

            Gee.ArrayList<WeatherInfo> result = new Gee.ArrayList<WeatherInfo>
                                                    ();
            Gee.ArrayList<Gee.ArrayList<GWeather.Info> > days = new Gee.
                                                                ArrayList<Gee.
                                                                          ArrayList
                                                                          <
                                                                              GWeather
                                                                              .
                                                                              Info> > ();

            for ( int i = 0; i < max_days; i++ ) {
                days.add (new Gee.ArrayList<GWeather.Info> ());
            }

            foreach ( GWeather.Info info in samples ) {
                long gwi_dtime;
                bool valid_date = info.get_value_update (out gwi_dtime);

                int64 bucket;

                if (!valid_date) {
                    continue;
                }

#if PRINT_WEATHER_DATA
                string dbg_str = gwc2str (info);
                debug ("WEATHER READING POINT: %s", dbg_str);
#endif
                if (gwi_dtime >= 0 && gwi_dtime >= today_unix) {
                    bucket = (gwi_dtime - today_unix) / DAY_SECONDS;
                    if (bucket < max_days) {
                        days[(int) bucket].add (info);
                    } else {
                    }
                    if (bucket == 1 && (first_tomorrow == null ||
                                        first_tomorrow_dtime > gwi_dtime)) {
                        first_tomorrow_dtime = gwi_dtime;
                        first_tomorrow = info;
                    }
                } else {
                    debug ("Encountered historic weather information");
                }
            }

            if (days[0].size == 0 && first_tomorrow != null) {
                int64 secs_left_today = DAY_SECONDS - (unix_now - today_unix);
                int64 secs_between = first_tomorrow_dtime - unix_now;

                if (secs_left_today < 90 * 60 && secs_between <= 180 * 60) {
                    days[0].add (first_tomorrow);
                }
            }

            foreach ( Gee.ArrayList<GWeather.Info> day in days ) {
                string temperature = null;
                string icon_name = null;

                if (compute_weather_info_data (day, days.index_of (day) == 0,
                                               out icon_name, out temperature))
                {
                    result.add (new WeatherInfo (cur_gdate, icon_name,
                                                 temperature));
                }
                Time tm;
                cur_gdate.to_time (out tm);
                debug ("computed info for day %d (%s) (t:%s, w:%s)", days.
                       index_of (day), tm.format ("%D"), temperature, icon_name)
                ;

                cur_gdate.add_days (1);
            }

            return result;
        }

        private bool compute_weather_info_data (Gee.ArrayList<GWeather.Info>
                                                samples, bool is_today, out
                                                string icon_name, out string
                                                temperature) {
            GWeather.Info phenomenon_gwi = null;
            GWeather.Info temp_gwi = null;

            bool phenomenon_supports_night_icon = false;
            bool has_daytime = false;
            double temp_val = double.NAN;
            int phenomenon_val = -1;

            foreach ( GWeather.Info sample in samples ) {
                int phenomenon = -1;
                bool supports_night_icon = false;
                bool valid_temp;
                double temp;

                icon_name = sample.get_icon_name ();

                if (icon_name != null) {
                    phenomenon = get_icon_name_sortkey (icon_name, out
                                                        supports_night_icon);
                }

                valid_temp = get_gweather_temperature (sample, out temp);

                if (phenomenon >= 0 && (phenomenon_gwi == null || phenomenon >
                                        phenomenon_val)) {
                    phenomenon_supports_night_icon = supports_night_icon;
                    phenomenon_val = phenomenon;
                    phenomenon_gwi = sample;
                }

                if (valid_temp && (temp_gwi == null || temp > temp_val)) {
                    temp_val = temp;
                    temp_gwi = sample;
                }

                if (sample.is_daytime ()) {
                    has_daytime = true;
                }
            }

            if (phenomenon_gwi != null && temp_gwi != null) {
                icon_name = get_normalized_icon_name (phenomenon_gwi, is_today
                                                      && !has_daytime &&
                                                      phenomenon_supports_night_icon);
                temperature = temp_gwi.get_temp_summary ();
                return true;
            } else {
                icon_name = null;
                temperature = null;
                return false;
            }
        }

        private int get_icon_name_sortkey (string icon_name, out bool
                                           supports_night_icon) {
            int normalized_name_len;
            int i;

            const WeatherIconInfo icons[] = {
                { "weather-clear", true },
                { "weather-few-clouds", true },
                { "weather-overcast", false },
                { "weather-fog", false },
                { "weather-showers-scattered", false },
                { "weather-showers", false },
                { "weather-snow", false },
                { "weather-storm", false },
                { "weather-severe-alert", false }
            };

            supports_night_icon = false;

            normalized_name_len = get_normalized_icon_name_len (icon_name);
            if (normalized_name_len < 0) {
                return -1;
            }

            for ( i = 0; i < icons.length; i++ ) {
                if (normalized_name_len == icons[i].name.length && icon_name.
                    slice (0, normalized_name_len) == icons[i].name) {
                    supports_night_icon = icons[i].night_support;
                    return i;
                }
            }

            warning ("Unknown weather icon '%s'", icon_name);

            return -1;
        }

        private int get_normalized_icon_name_len (string str) {
            const string suffix1 = "-symbolic";
            int suffix1_len = suffix1.length;

            const string suffix2 = "-night";
            int suffix2_len = suffix2.length;

            int str_len = str.length;
            int clean_len = str_len - suffix1_len;

            if (clean_len >= 0 && str.slice (clean_len, clean_len + suffix1_len)
                == suffix1) {
                str_len = clean_len;
            }

            clean_len = str_len - suffix2_len;
            if (clean_len >= 0 && str.slice (clean_len, clean_len + suffix2_len)
                == suffix2) {
                str_len = clean_len;
            }

            return str_len;
        }

        private string get_normalized_icon_name (GWeather.Info wi, bool
                                                 is_night_icon) {
            string icon_name = wi.get_icon_name ();

            return icon_name.replace ("-symbolic", "").replace ("-night", "");
        }

        private bool get_time_day_start (out Date ret_date, out int64 ret_unix,
                                         out int64 ret_unix_exact) {
            TimeZone zone = timezone == null ? new TimeZone.local () : timezone;

            DateTime now = new DateTime.now (zone);
            DateTime day = new DateTime (zone,
                                         now.get_year (),
                                         now.get_month (),
                                         now.get_day_of_month (),
                                         0, 0, 0);

            ret_date.set_dmy ((DateDay) day.get_day_of_month (), day.get_month
                                  (), (DateYear) day.get_year ());

            ret_unix = day.to_unix ();
            ret_unix_exact = now.to_unix ();

            return true;
        }

        private void start_timer () {
            debug ("start timers");
            NetworkMonitor monitor = NetworkMonitor.get_default ();
            if (monitor.get_network_available ()) {
                update_timeout_interval ();
                duration_timer.start ();

                schedule_midnight ();
                midnight_timer.start ();
            }
        }

        private void stop_timer () {
            debug ("stop timers");
            duration_timer.stop ();
            midnight_timer.stop ();
        }

        private void update_timeout_interval () {
            uint interval;

            if (has_valid_weather_infos ()) {
                interval = check_interval_renew;
            } else {
                interval = check_interval_new;
            }
            debug ("setting timer interval to %u", interval);
            duration_timer.default_duration = interval;
        }

        private void schedule_midnight () {
            TimeZone zone = timezone == null ? new TimeZone.local () : timezone;
            DateTime now = new DateTime.now (zone);
            DateTime tom = now.add_days (1);
            DateTime mid = new DateTime (zone,
                                         tom.get_year (),
                                         tom.get_month (),
                                         tom.get_day_of_month (),
                                         0, 0, 0);
            int64 real_now = now.to_unix ();
            int64 real_mid = mid.to_unix ();

            debug ("scheduling midnight in %d", (int) (real_mid - real_now));

            midnight_timer.default_duration = real_mid - real_now;
        }

        private bool has_valid_weather_infos () {
            if (gweather_info == null || weather_infos_updated < 0) {
                return false;
            }

            int64 now = get_monotonic_time ();

            return (now - weather_infos_updated) / 1000000 <= valid_timespan;
        }

        private void update () {
            debug ("update weather service");
            if (!weather_service_running) {
                weather_is_stale = true;
                return;
            } else {
                weather_is_stale = false;
            }

            if (gweather_info != null) {
                gweather_info.update ();
                update_timeout_interval ();

                if (duration_timer.is_running ()) {
                    duration_timer.reset ();
                }
            }
        }

        /* Callbacks */
        private void on_network_changed_cb (NetworkMonitor monitor, bool
                                            available) {
            info("nw changed, available: %b", available);
            bool is_running = duration_timer.is_running ();

            if (available && !is_running) {
                if (gweather_info != null) {
                    gweather_info.update ();
                }
                start_timer ();
            } else if (!available && is_running) {
                stop_timer ();
            }
        }

        private bool on_duration_timer_timeout () {
            debug ("duration timer timeout");
            if (gweather_info != null) {
                gweather_info.update ();
            }
            return true;
        }

        private bool on_midnight_timer_timeout () {
            debug ("midnight timer timeout");
            if (gweather_info != null) {
                gweather_info.update ();
            }
            if (duration_timer.is_running ()) {
                duration_timer.reset ();
            }
            return true;
        }

        private void on_gclue_location_changed_cb (GClue.Location location) {
            update_gclue_location (location);
        }

        private void on_gweather_update_cb (GWeather.Info info) {
            update_weather (info, true);
        }

        /* signals */
        public signal void weather_changed () {
            debug ("weather changed");
        }

        /* Manage weather service */
        public void activate () {
            active = true;
            start_stop ();
        }

        public void deactivate () {
            active = false;
            start_stop ();
        }

        private void start_stop () {
            if (active && use_count > 0) {
                start ();
            } else {
                stop ();
            }
        }

        private void start () {
            if (weather_service_running && location_service_running) {
                return;
            }

            info ("Starting weather service");

            weather_service_running = true;

            if (location == null) {
                location_service_running = true;

                location_cancellable.cancel ();
                location_cancellable.reset ();

                create_gclue_simple.begin ((obj, res) => {
                    try {
                        location_service = create_gclue_simple.end (res);
                        GClue.Location location = location_service.get_location
                                                      ();
                        GClue.Client client = location_service.get_client ();

                        if (location != null) {
                            update_gclue_location (location);
                            location.notify["location"].connect ((sender,
                                                                  property) => {
                                on_gclue_location_changed_cb (location);
                            });
                        }
                    } catch (Error err) {
                        if (!err.matches (IOError.quark (), IOError.CANCELLED)
                            && !(
                                DBusError.is_remote_error (err) && (DBusError.
                                                                    get_remote_error
                                                                        (err) !=
                                                                    "org.freedesktop.DBus.Error.AccessDenied")))
                        {
                            warning (
                                "Could not create GCLueSimple: %s (%s)", err
                                .message, err.domain.to_string ()
                                );
                        } else {
                            debug ("Could not create GCLueSimple: %s", err.
                                   message);
                        }
                        if (DBusError.is_remote_error (err)) {
                            debug ("DBusError: %s", DBusError.
                                   get_remote_error (err));
                        }
                    }
                });
            } else {
                location_service_running = false;

                update_location (location);
            }

            if (weather_is_stale) {
                update ();
            }
        }

        private void stop () {
        }

        public void release () {
            use_count--;
            start_stop ();
        }

        public void hold () {
            use_count++;
            start_stop ();
        }

        /* async wrapper for GClue.Simple */
        private async GClue.Simple create_gclue_simple () throws Error {
            debug ("create_gclue_simple");
            GClue.Simple gclue = yield new GClue.Simple (
                "com.example.GtkApplication", GClue.
                AccuracyLevel.CITY,
                location_cancellable);
            return gclue;
        }
    }

#if PRINT_WEATHER_DATA
    private string gwc2str (GWeather.Info info) {
        long update;

        if (!info.get_value_update (out update)) {
            return "<null>";
        }

        DateTime date = new DateTime.from_unix_local (update);

        string date_str = date.format ("%F %T");

        double temp;
        get_gweather_temperature (info, out temp);

        string icon_name = info.get_symbolic_icon_name ();

        return "(%s: t:%f, w:%s)".printf (date_str, temp, icon_name);
    }
#endif

    private bool get_gweather_temperature (GWeather.Info info, out double temp){
        double value;
        bool valid = info.get_value_temp (GWeather.TemperatureUnit.DEFAULT, out
                                          value);

        if (valid) {
            temp = value;
        } else {
            temp = double.NAN;
        }

        return valid;
    }
}
