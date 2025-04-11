namespace GtkCal {
    class WeatherInfo : Object {
        public string icon_name {
            get;
            set;
        }
        public string temperature {
            get;
            set;
        }
        public Date date {
            get;
            set;
        }

        public WeatherInfo (Date date, string icon_name, string temperature) {
            Object (date: date, icon_name: icon_name, temperature: temperature);
        }

        construct {
        }
    }
}
